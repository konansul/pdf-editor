import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../providers.dart';
import '../services/ocr_service.dart';
import '../ui/components.dart';
import '../ui/sharing.dart';
import '../ui/theme.dart';

enum ExportFormat { images, longImage, word, slides, text }

extension ExportFormatDetails on ExportFormat {
  String get title => switch (this) {
        ExportFormat.images => 'Images',
        ExportFormat.longImage => 'One long image',
        ExportFormat.word => 'Word document',
        ExportFormat.slides => 'PowerPoint',
        ExportFormat.text => 'Text file',
      };

  String get detail => switch (this) {
        ExportFormat.images => 'A JPEG for every page',
        ExportFormat.longImage => 'Every page stacked into one tall JPEG',
        ExportFormat.word => 'Recognised text as .docx, without the layout',
        ExportFormat.slides => 'A .pptx with one page per slide',
        ExportFormat.text => 'Recognised text as plain .txt',
      };

  IconData get icon => switch (this) {
        ExportFormat.images => Icons.photo_library_outlined,
        ExportFormat.longImage => Icons.view_day_outlined,
        ExportFormat.word => Icons.description_outlined,
        ExportFormat.slides => Icons.slideshow_outlined,
        ExportFormat.text => Icons.notes_outlined,
      };

  bool get readsText => this == ExportFormat.word || this == ExportFormat.text;
}

class ConvertScreen extends ConsumerStatefulWidget {
  const ConvertScreen({super.key, required this.document, required this.format});

  final Document document;
  final ExportFormat format;

  @override
  ConsumerState<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends ConsumerState<ConvertScreen> {
  List<File> _results = const [];
  String? _failure;
  int _done = 0;
  int _total = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final source = File(widget.document.filePath);
    final name = widget.document.name;
    final exporter = ref.read(exportProvider);

    void progress(int done, int total) {
      if (!mounted) return;
      setState(() {
        _done = done;
        _total = total;
      });
    }

    try {
      final results = switch (widget.format) {
        ExportFormat.images => await exporter.pageImages(source, name, onProgress: progress),
        ExportFormat.longImage => [
            await exporter.longImage(source, name, onProgress: progress),
          ],
        ExportFormat.slides => [
            await exporter.slideDeck(source, name, onProgress: progress),
          ],
        ExportFormat.word => [
            await exporter.wordDocument(
              name,
              await ref.read(ocrProvider).recognize(source, onProgress: progress),
            ),
          ],
        ExportFormat.text => [
            await exporter.textFile(
              name,
              _joinPages(await ref.read(ocrProvider).recognize(source, onProgress: progress)),
            ),
          ],
      };

      if (!mounted) return;
      setState(() {
        _results = results;
        _running = false;
      });
      await _share();
    } on OcrUnavailable {
      _fail('Text recognition is not available on this device.');
    } catch (error) {
      _fail('The document could not be converted.');
    }
  }

  String _joinPages(List<String> pages) {
    final written = <String>[];
    for (var index = 0; index < pages.length; index++) {
      written.add('Page ${index + 1}\n\n${pages[index]}');
    }
    return written.join('\n\n');
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _failure = message;
      _running = false;
    });
  }

  Future<void> _share() async {
    if (_results.isEmpty || !mounted) return;
    await shareFiles(context, _results, subject: widget.document.name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return AppScaffold(
      title: widget.format.title,
      largeTitle: false,
      leading: const AppBackButton(),
      footer: _running
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_failure == null) AppButton(label: 'Share', onPressed: _share),
                  if (_failure == null) const SizedBox(height: 8),
                  AppButton(
                    label: 'Done',
                    plain: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_running) ...[
                const AppSpinner(),
                const SizedBox(height: 20),
                Text(
                  _total == 0
                      ? 'Opening the document'
                      : widget.format.readsText
                          ? 'Reading page $_done of $_total'
                          : 'Rendering page $_done of $_total',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: colors.muted),
                ),
              ] else if (_failure != null) ...[
                Icon(Icons.error_outline, size: 30, color: colors.danger),
                const SizedBox(height: 14),
                Text(
                  _failure!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4, color: colors.muted),
                ),
              ] else ...[
                Icon(Icons.check_circle_outline, size: 30, color: colors.accent),
                const SizedBox(height: 14),
                Text(
                  _results.length == 1
                      ? 'Ready to share'
                      : '${_results.length} images ready to share',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.format.readsText
                      ? 'The text was read on this device. Layout and images are not carried over.'
                      : 'Nothing left the device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4, color: colors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
