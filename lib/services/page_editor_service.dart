import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

class PageEdit {
  const PageEdit({required this.order, required this.rotations});

  final List<int> order;
  final Map<int, int> rotations;
}

class PageEditorService {
  const PageEditorService();

  Future<File> apply(File source, PageEdit edit) async {
    final pdf = Pdf();
    try {
      final editor = await pdf.edit(FileSource(source));

      for (final entry in edit.rotations.entries) {
        if (entry.value % 360 == 0) continue;
        await editor.rotatePage(entry.key, degrees: entry.value);
      }

      final original = List<int>.generate(await editor.pageCount, (index) => index + 1);
      final kept = edit.order.toSet();
      for (final page in original.reversed) {
        if (!kept.contains(page)) await editor.deletePage(page);
      }

      final remaining = original.where(kept.contains).toList();
      for (var target = 0; target < edit.order.length; target++) {
        final page = edit.order[target];
        final from = remaining.indexOf(page);
        if (from == target) continue;
        await editor.movePage(from: from + 1, to: target + 1);
        remaining.removeAt(from);
        remaining.insert(target, page);
      }

      final directory = await getTemporaryDirectory();
      final output = File(p.join(directory.path, 'edit-${DateTime.now().millisecondsSinceEpoch}.pdf'));
      await editor.save(await FileSink.create(output));
      await editor.dispose();
      return output;
    } finally {
      await pdf.dispose();
    }
  }
}
