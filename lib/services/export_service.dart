import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import 'office_writer.dart';

class ExportFailed implements Exception {
  const ExportFailed();
}

typedef ExportProgress = void Function(int done, int total);

class ExportService {
  const ExportService();

  static const _pageWidth = 1400.0;
  static const _stripWidth = 1000.0;
  static const _stripMaxHeight = 14000.0;
  static const _office = OfficeWriter();

  Future<List<File>> pageImages(File pdf, String name, {ExportProgress? onProgress}) async {
    final directory = await _workspace();
    final files = <File>[];

    await _eachPage(pdf, (page, number, total) async {
      final image = await _render(page, _pageWidth);
      if (image == null) return;

      final file = File(p.join(directory.path, '${_safe(name)}-$number.jpg'));
      await file.writeAsBytes(image);
      files.add(file);
      onProgress?.call(number, total);
    });

    if (files.isEmpty) throw const ExportFailed();
    return files;
  }

  Future<File> longImage(File pdf, String name, {ExportProgress? onProgress}) async {
    PdfDocument? document;

    try {
      document = await PdfDocument.openFile(pdf.path);
      final total = document.pagesCount;
      if (total == 0) throw const ExportFailed();

      final ratios = <double>[];
      for (var number = 1; number <= total; number++) {
        final page = await document.getPage(number);
        ratios.add(page.height / page.width);
        await page.close();
      }

      var width = _stripWidth;
      var height = ratios.fold<double>(0, (sum, ratio) => sum + ratio) * width;
      if (height > _stripMaxHeight) {
        width = width * (_stripMaxHeight / height);
        height = _stripMaxHeight;
      }

      final strip = img.Image(width: width.round(), height: height.round());
      img.fill(strip, color: img.ColorRgb8(255, 255, 255));

      var offset = 0;
      for (var number = 1; number <= total; number++) {
        final page = await document.getPage(number);
        final bytes = await _render(page, width);
        await page.close();

        if (bytes != null) {
          final decoded = img.decodeJpg(bytes);
          if (decoded != null) {
            img.compositeImage(strip, decoded, dstX: 0, dstY: offset);
            offset += decoded.height;
          }
        }

        onProgress?.call(number, total);
      }

      final directory = await _workspace();
      final file = File(p.join(directory.path, '${_safe(name)}-full.jpg'));
      await file.writeAsBytes(img.encodeJpg(strip, quality: 88));
      return file;
    } finally {
      await document?.close();
    }
  }

  Future<File> textFile(String name, String text) async {
    final directory = await _workspace();
    final file = File(p.join(directory.path, '${_safe(name)}.txt'));
    await file.writeAsString(text);
    return file;
  }

  Future<File> wordDocument(String name, List<String> pages) async {
    final directory = await _workspace();
    final file = File(p.join(directory.path, '${_safe(name)}.docx'));
    await file.writeAsBytes(_office.wordDocument(pages));
    return file;
  }

  Future<File> slideDeck(File pdf, String name, {ExportProgress? onProgress}) async {
    final slides = <Uint8List>[];
    var aspect = 297 / 210;

    await _eachPage(pdf, (page, number, total) async {
      if (number == 1) aspect = page.height / page.width;
      final image = await _render(page, _pageWidth);
      if (image != null) slides.add(image);
      onProgress?.call(number, total);
    });

    if (slides.isEmpty) throw const ExportFailed();

    final directory = await _workspace();
    final file = File(p.join(directory.path, '${_safe(name)}.pptx'));
    await file.writeAsBytes(_office.slideDeck(slides, aspect: aspect));
    return file;
  }

  Future<void> _eachPage(
    File pdf,
    Future<void> Function(PdfPage page, int number, int total) body,
  ) async {
    PdfDocument? document;

    try {
      document = await PdfDocument.openFile(pdf.path);
      final total = document.pagesCount;
      if (total == 0) throw const ExportFailed();

      for (var number = 1; number <= total; number++) {
        final page = await document.getPage(number);
        try {
          await body(page, number, total);
        } finally {
          await page.close();
        }
      }
    } finally {
      await document?.close();
    }
  }

  Future<Uint8List?> _render(PdfPage page, double width) async {
    final scale = width / page.width;
    final image = await page.render(
      width: page.width * scale,
      height: page.height * scale,
      format: PdfPageImageFormat.jpeg,
      backgroundColor: '#FFFFFF',
      quality: 90,
    );
    return image?.bytes;
  }

  Future<Directory> _workspace() async {
    final base = await getTemporaryDirectory();
    final directory = Directory(
      p.join(base.path, 'exports', DateTime.now().microsecondsSinceEpoch.toString()),
    );
    await directory.create(recursive: true);
    return directory;
  }

  String _safe(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return cleaned.isEmpty ? 'Document' : cleaned;
  }
}
