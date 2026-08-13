import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DocumentDatabase {
  static const _fileName = 'collate.db';
  static const _version = 2;

  Database? _db;

  Future<Database> open() async {
    final existing = _db;
    if (existing != null) return existing;

    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, _fileName);

    final db = await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            file_path TEXT NOT NULL,
            thumbnail_path TEXT,
            page_count INTEGER NOT NULL,
            byte_size INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            folder_id TEXT
          )
        ''');
        await db.execute('CREATE INDEX documents_updated_at ON documents (updated_at DESC)');
        await db.execute('CREATE INDEX documents_name ON documents (name)');
        await db.execute('CREATE INDEX documents_folder ON documents (folder_id)');
        await _createFolders(db);
      },
      onUpgrade: (db, from, to) async {
        if (from < 2) {
          await db.execute('ALTER TABLE documents ADD COLUMN folder_id TEXT');
          await db.execute('CREATE INDEX documents_folder ON documents (folder_id)');
          await _createFolders(db);
        }
      },
    );

    _db = db;
    return db;
  }

  Future<void> _createFolders(Database db) async {
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }
}
