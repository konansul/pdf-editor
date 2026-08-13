import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfBuilder {
  const PdfBuilder();

  static const _pageWidth = 595.0;

  Future<Uint8List> fromImages(List<File> images) async {
    final document = pw.Document();

    for (final file in images) {
      final bytes = await file.readAsBytes();
      final image = pw.MemoryImage(bytes);

      final width = image.width?.toDouble() ?? _pageWidth;
      final height = image.height?.toDouble() ?? _pageWidth;
      final pageHeight = _pageWidth * (height / width);

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(_pageWidth, pageHeight, marginAll: 0),
          build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }

    return document.save();
  }
}
