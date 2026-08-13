import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class ScannerCancelled implements Exception {
  const ScannerCancelled();
}

class ScannerPermissionDenied implements Exception {
  const ScannerPermissionDenied();
}

class ScannerService {
  const ScannerService();

  Future<File> scanToPdf() async {
    List<String>? result;
    try {
      result = await CunningDocumentScanner.getPictures(
        scannerSource: ScannerSource.cameraAndGallery,
        asPdf: true,
      );
    } on CunningDocumentScannerException {
      throw const ScannerPermissionDenied();
    }

    if (result == null || result.isEmpty) throw const ScannerCancelled();

    final file = File(result.first);
    if (!await file.exists()) throw const ScannerCancelled();
    return file;
  }
}
