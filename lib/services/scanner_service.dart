import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerCancelled implements Exception {
  const ScannerCancelled();
}

class ScannerPermissionDenied implements Exception {
  const ScannerPermissionDenied();
}

class ScannerPermissionBlocked implements Exception {
  const ScannerPermissionBlocked();
}

class ScannerFailed implements Exception {
  const ScannerFailed(this.reason);

  final String reason;
}

class ScannerService {
  const ScannerService();

  Future<void> ensureCamera() async {
    var status = await Permission.camera.status;

    if (status.isGranted || status.isLimited) return;

    if (status.isPermanentlyDenied || status.isRestricted) {
      throw const ScannerPermissionBlocked();
    }

    status = await Permission.camera.request();

    if (status.isGranted || status.isLimited) return;
    if (status.isPermanentlyDenied || status.isRestricted) {
      throw const ScannerPermissionBlocked();
    }
    throw const ScannerPermissionDenied();
  }

  Future<void> openSettings() => openAppSettings();

  Future<File> scanToPdf() async {
    await ensureCamera();

    List<String>? result;
    try {
      result = await CunningDocumentScanner.getPictures(
        scannerSource: ScannerSource.cameraAndGallery,
        asPdf: true,
      );
    } on CunningDocumentScannerException catch (error) {
      throw ScannerFailed(error.toString());
    } catch (error) {
      throw ScannerFailed(error.toString());
    }

    if (result == null || result.isEmpty) throw const ScannerCancelled();

    final file = File(result.first);
    if (!await file.exists()) throw const ScannerCancelled();
    return file;
  }
}
