import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../models/document.dart';
import '../providers.dart';
import '../ui/components.dart';
import '../ui/sheets.dart';
import '../ui/theme.dart';

class SplitScreen extends ConsumerStatefulWidget {
  const SplitScreen({super.key, required this.document});

  final Document document;

  @override
  ConsumerState<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends ConsumerState<SplitScreen> {
  final _thumbnails = <int, Uint8List?>{};
  final _selected = <int>{};
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(widget.document.filePath);
      for (var number = 1; number <= document.pagesCount; number++) {
        final page = await document.getPage(number);
        final scale = 200 / page.width;
        final image = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        _thumbnails[number] = image?.bytes;
      }
    } catch (_) {
      _thumbnails.clear();
    } finally {
      await document?.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return AppScaffold(
      title: 'Split',
      largeTitle: false,
      leading: const AppBackButton(),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selected.isEmpty
                  ? 'Tap the pages you want in the new document.'
                  : '${_selected.length} of ${_thumbnails.length} pages selected',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Create document',
              busy: _busy,
              onPressed: _selected.isEmpty ? null : _extract,
            ),
          ],
        ),
      ),
      child: _loading
          ? const AppSpinner()
          : _thumbnails.isEmpty
              ? const AppEmptyState(
                  title: 'Could not read this document',
                  detail: 'Its pages could not be opened.',
                )
              : _grid(colors),
    );
  }

  Widget _grid(AppColors colors) {
    final numbers = _thumbnails.keys.toList()..sort();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 0.66,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final number = numbers[index];
        final chosen = _selected.contains(number);
        final bytes = _thumbnails[number];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            if (chosen) {
              _selected.remove(number);
            } else {
              _selected.add(number);
            }
          }),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(radiusSmall),
                    border: Border.all(
                      color: chosen ? colors.accent : colors.hairline,
                      width: chosen ? 2.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: bytes == null
                      ? Icon(Icons.description_outlined, color: colors.muted)
                      : Image.memory(bytes, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: chosen ? FontWeight.w700 : FontWeight.w400,
                  color: chosen ? colors.accent : colors.muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _extract() async {
    final pages = _selected.toList()..sort();
    final name = '${widget.document.name} (${pages.length} pages)';

    setState(() => _busy = true);
    try {
      await ref.read(libraryProvider.notifier).extractPages(widget.document, pages, name);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        await notify(
          context,
          title: 'Could not split',
          message: 'Those pages could not be extracted.',
        );
      }
    }
  }
}
