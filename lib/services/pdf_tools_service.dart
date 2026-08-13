import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

class PdfToolsService {
  const PdfToolsService();

  Future<File> extract(File source, List<int> pages) async {
    final pdf = Pdf();
    try {
      final output = await _scratch('extract');
      await pdf.extractPages(
        FileSource(source),
        await FileSink.create(output),
        pages: pages,
      );
      return output;
    } finally {
      await pdf.dispose();
    }
  }

  Future<File> compress(File source, {int quality = 60}) async {
    final pdf = Pdf();
    try {
      final editor = await pdf.edit(FileSource(source));
      await editor.optimizeImages(quality: quality);

      final output = await _scratch('compress');
      await editor.save(
        await FileSink.create(output),
        options: const PdfSaveOptions.fullRewrite(compress: true, garbageCollect: true),
      );
      await editor.dispose();
      return output;
    } finally {
      await pdf.dispose();
    }
  }

  Future<File> protect(File source, String password) async {
    final pdf = Pdf();
    try {
      final editor = await pdf.edit(FileSource(source));

      final output = await _scratch('locked');
      await editor.save(
        await FileSink.create(output),
        options: PdfSaveOptions.fullRewrite(
          encryption: PdfEncryption.config(
            ownerPassword: password,
            userPassword: password,
          ),
        ),
      );
      await editor.dispose();
      return output;
    } finally {
      await pdf.dispose();
    }
  }

  Future<File> _scratch(String prefix) async {
    final directory = await getTemporaryDirectory();
    return File(p.join(directory.path, '$prefix-${DateTime.now().millisecondsSinceEpoch}.pdf'));
  }
}
