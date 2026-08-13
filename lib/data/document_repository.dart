import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';

import '../models/document.dart';
import '../models/folder.dart';
import '../services/pdf_builder.dart';
import 'document_database.dart';

class UnreadablePdf implements Exception {
  const UnreadablePdf();
}

class DocumentRepository {
  DocumentRepository(this._database);

  final DocumentDatabase _database;
  final _uuid = const Uuid();

  Future<List<Document>> load({String query = '', DocumentSort sort = DocumentSort.newest}) async {
    final db = await _database.open();

    final where = query.trim().isEmpty ? null : 'name LIKE ?';
    final args = query.trim().isEmpty ? null : <Object>['%${query.trim()}%'];

    final rows = await db.query(
      'documents',
      where: where,
      whereArgs: args,
      orderBy: switch (sort) {
        DocumentSort.newest => 'updated_at DESC',
        DocumentSort.oldest => 'updated_at ASC',
        DocumentSort.name => 'name COLLATE NOCASE ASC',
      },
    );

    return rows.map(Document.fromRow).toList();
  }

  Future<List<Folder>> loadFolders() async {
    final db = await _database.open();
    final rows = await db.query('folders', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Folder.fromRow).toList();
  }

  Future<Folder> createFolder(String name) async {
    final folder = Folder(id: _uuid.v4(), name: name, createdAt: DateTime.now());
    final db = await _database.open();
    await db.insert('folders', folder.toRow());
    return folder;
  }

  Future<void> renameFolder(Folder folder, String name) async {
    final db = await _database.open();
    await db.update('folders', {'name': name}, where: 'id = ?', whereArgs: [folder.id]);
  }

  Future<void> deleteFolder(Folder folder) async {
    final db = await _database.open();
    await db.update(
      'documents',
      {'folder_id': null},
      where: 'folder_id = ?',
      whereArgs: [folder.id],
    );
    await db.delete('folders', where: 'id = ?', whereArgs: [folder.id]);
  }

  Future<void> move(Document document, String? folderId) async {
    final db = await _database.open();
    await db.update(
      'documents',
      {'folder_id': folderId, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<Document> importImages(List<File> images, {required String name, String? folderId}) async {
    final bytes = await const PdfBuilder().fromImages(images);

    final id = _uuid.v4();
    final storage = await _documentsDirectory();
    final destination = File(p.join(storage.path, '$id.pdf'));
    await destination.writeAsBytes(bytes);

    return _register(id, destination, name, folderId);
  }

  Future<Document> importPdf(
    File source, {
    String? name,
    String? folderId,
    int? lockedPageCount,
  }) async {
    final id = _uuid.v4();
    final storage = await _documentsDirectory();
    final destination = File(p.join(storage.path, '$id.pdf'));
    await source.copy(destination.path);

    return _register(
      id,
      destination,
      name ?? _nameFrom(source.path),
      folderId,
      lockedPageCount: lockedPageCount,
    );
  }

  Future<Document> _register(
    String id,
    File destination,
    String name,
    String? folderId, {
    int? lockedPageCount,
  }) async {
    final pageCount = lockedPageCount ?? await _readPageCount(destination);
    if (pageCount == 0) {
      if (await destination.exists()) await destination.delete();
      throw const UnreadablePdf();
    }

    final thumbnail = lockedPageCount == null ? await _renderThumbnail(destination, id) : null;

    final now = DateTime.now();
    final document = Document(
      id: id,
      name: name,
      filePath: destination.path,
      thumbnailPath: thumbnail?.path,
      pageCount: pageCount,
      byteSize: await destination.length(),
      createdAt: now,
      updatedAt: now,
      folderId: folderId,
    );

    final db = await _database.open();
    await db.insert('documents', document.toRow());
    return document;
  }

  Future<void> replaceFile(Document document, File source) async {
    final destination = File(document.filePath);
    await source.copy(destination.path);

    final pageCount = await _readPageCount(destination);
    final thumbnail = await _renderThumbnail(destination, document.id);

    final db = await _database.open();
    await db.update(
      'documents',
      {
        'page_count': pageCount,
        'byte_size': await destination.length(),
        'thumbnail_path': thumbnail?.path,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> rename(Document document, String name) async {
    final db = await _database.open();
    await db.update(
      'documents',
      {'name': name, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> delete(Document document) async {
    final db = await _database.open();
    await db.delete('documents', where: 'id = ?', whereArgs: [document.id]);

    for (final path in [document.filePath, document.thumbnailPath]) {
      if (path == null) continue;
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<Directory> _documentsDirectory() async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'documents'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<int> _readPageCount(File file) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(file.path);
      return document.pagesCount;
    } catch (_) {
      return 0;
    } finally {
      await document?.close();
    }
  }

  Future<File?> _renderThumbnail(File source, String id) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(source.path);
      if (document.pagesCount == 0) return null;

      final page = await document.getPage(1);
      final scale = 320 / page.width;
      final image = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();
      if (image == null) return null;

      final storage = await _thumbnailsDirectory();
      final file = File(p.join(storage.path, '$id.png'));
      await file.writeAsBytes(image.bytes);
      return file;
    } catch (_) {
      return null;
    } finally {
      await document?.close();
    }
  }

  Future<Directory> _thumbnailsDirectory() async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'thumbnails'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  String _nameFrom(String path) {
    final base = p.basenameWithoutExtension(path).trim();
    return base.isEmpty ? 'Untitled' : base;
  }
}
