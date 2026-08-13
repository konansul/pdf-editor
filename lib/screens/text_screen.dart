import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../providers.dart';
import '../services/ocr_service.dart';
import '../ui/components.dart';
import '../ui/sharing.dart';
import '../ui/sheets.dart';
import '../ui/theme.dart';

class TextScreen extends ConsumerStatefulWidget {
  const TextScreen({super.key, required this.document});

  final Document document;

  @override
  ConsumerState<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends ConsumerState<TextScreen> {
  List<String> _pages = const [];
  String? _failure;
  int _done = 0;
  int _total = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    try {
      final pages = await ref.read(ocrProvider).recognize(
        File(widget.document.filePath),
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _done = done;
            _total = total;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _pages = pages;
        _running = false;
      });
    } on OcrUnavailable {
      _fail('Text recognition is not available on this device.');
    } catch (error) {
      _fail('The pages of this document could not be read.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _failure = message;
      _running = false;
    });
  }

  bool get _empty => _pages.every((page) => page.trim().isEmpty);

  String get _plain {
    final written = <String>[];
    for (var index = 0; index < _pages.length; index++) {
      if (_pages[index].trim().isEmpty) continue;
      written.add('Page ${index + 1}\n\n${_pages[index]}');
    }
    return written.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final ready = !_running && _failure == null && !_empty;

    return AppScaffold(
      title: 'Text',
      largeTitle: false,
      leading: const AppBackButton(),
      actions: [
        AppIconButton(icon: Icons.copy_all_outlined, onPressed: ready ? _copy : null),
        AppIconButton(icon: Icons.ios_share, onPressed: ready ? _share : null),
      ],
      child: _body(colors),
    );
  }

  Widget _body(AppColors colors) {
    if (_running) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSpinner(),
            const SizedBox(height: 20),
            Text(
              _total == 0 ? 'Opening the document' : 'Reading page $_done of $_total',
              style: TextStyle(fontSize: 15, color: colors.muted),
            ),
          ],
        ),
      );
    }

    if (_failure != null) {
      return AppEmptyState(title: 'Could not read this document', detail: _failure!);
    }

    if (_empty) {
      return const AppEmptyState(
        title: 'No text found',
        detail: 'These pages look like images without readable words on them.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: _pages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 26),
      itemBuilder: (context, index) {
        final text = _pages[index].trim();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Page ${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              text.isEmpty ? 'Nothing readable on this page.' : text,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: text.isEmpty ? colors.muted : colors.ink,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _plain));
    if (!mounted) return;
    await notify(
      context,
      title: 'Copied',
      message: 'The recognised text is on your clipboard.',
    );
  }

  Future<void> _share() async {
    final file = await ref.read(exportProvider).textFile(widget.document.name, _plain);
    if (!mounted) return;
    await shareFiles(context, [file], subject: widget.document.name);
  }
}
