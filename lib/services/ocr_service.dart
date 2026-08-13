import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class OcrUnavailable implements Exception {
  const OcrUnavailable();
}

class OcrService {
  const OcrService();

  static const _channel = MethodChannel('collate/ocr');
  static const _renderWidth = 1600.0;

  Future<List<String>> recognize(
    File pdf, {
    void Function(int done, int total)? onProgress,
  }) async {
    final temporary = await getTemporaryDirectory();
    final workspace = Directory(
      p.join(temporary.path, 'ocr-${DateTime.now().microsecondsSinceEpoch}'),
    );
    await workspace.create(recursive: true);

    PdfDocument? document;
    final pages = <String>[];

    try {
      document = await PdfDocument.openFile(pdf.path);
      final total = document.pagesCount;

      for (var number = 1; number <= total; number++) {
        final page = await document.getPage(number);
        final scale = _renderWidth / page.width;
        final image = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        await page.close();

        if (image == null) {
          pages.add('');
          onProgress?.call(number, total);
          continue;
        }

        final file = File(p.join(workspace.path, 'page-$number.png'));
        await file.writeAsBytes(image.bytes);

        try {
          final text = await _channel.invokeMethod<String>('recognize', {'path': file.path});
          pages.add(text?.trim() ?? '');
        } on MissingPluginException {
          throw const OcrUnavailable();
        } finally {
          if (await file.exists()) await file.delete();
        }

        onProgress?.call(number, total);
      }
    } finally {
      await document?.close();
      if (await workspace.exists()) await workspace.delete(recursive: true);
    }

    return pages;
  }
}
