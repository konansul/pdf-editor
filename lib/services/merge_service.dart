import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

class MergeService {
  const MergeService();

  Future<File> merge(List<File> sources) async {
    if (sources.length < 2) throw ArgumentError('merge needs at least two documents');

    final directory = await getTemporaryDirectory();
    final output = p.join(directory.path, 'merge-${DateTime.now().millisecondsSinceEpoch}.pdf');

    final path = await PdfCombiner.mergeMultiplePDFs(
      inputs: sources.map((file) => MergeInput.path(file.path)).toList(),
      outputPath: output,
    );

    return File(path);
  }
}
