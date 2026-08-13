import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareFiles(BuildContext context, List<File> files, {String? subject}) async {
  final box = context.findRenderObject() as RenderBox?;

  await SharePlus.instance.share(
    ShareParams(
      subject: subject,
      files: [for (final file in files) XFile(file.path)],
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
