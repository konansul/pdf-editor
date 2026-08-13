import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../models/document.dart';
import '../providers.dart';
import '../services/page_editor_service.dart';
import '../ui/components.dart';
import '../ui/sheets.dart';
import '../ui/theme.dart';

class PagesScreen extends ConsumerStatefulWidget {
  const PagesScreen({super.key, required this.document});

  final Document document;

  @override
  ConsumerState<PagesScreen> createState() => _PagesScreenState();
}

class _Page {
  _Page({required this.number, required this.thumbnail});

  final int number;
  final Uint8List? thumbnail;
  int rotation = 0;
  bool removed = false;
}

class _PagesScreenState extends ConsumerState<PagesScreen> {
  final _pages = <_Page>[];
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;

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
        final scale = 220 / page.width;
        final image = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        _pages.add(_Page(number: number, thumbnail: image?.bytes));
      }
    } catch (_) {
      _pages.clear();
    } finally {
      await document?.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final canSave = _changed && !_saving && _pages.any((page) => !page.removed);

    return AppScaffold(
      title: 'Pages',
      largeTitle: false,
      leading: const AppBackButton(),
      actions: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canSave ? _save : null,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: canSave ? colors.accent : colors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      child: _loading
          ? const AppSpinner()
          : _pages.isEmpty
              ? const AppEmptyState(
                  title: 'Could not read this document',
                  detail: 'Its pages could not be opened.',
                )
              : _list(colors),
    );
  }

  Widget _list(AppColors colors) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _pages.length,
      buildDefaultDragHandles: false,
      onReorderItem: (from, to) => setState(() {
        final page = _pages.removeAt(from);
        _pages.insert(to, page);
        _changed = true;
      }),
      itemBuilder: (context, index) {
        final page = _pages[index];

        return Container(
          key: ValueKey(page.number),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radiusSmall),
            border: Border.all(color: colors.hairline),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: page.removed ? 0.3 : 1,
                child: RotatedBox(
                  quarterTurns: page.rotation ~/ 90,
                  child: Container(
                    width: 46,
                    height: 60,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                    clipBehavior: Clip.antiAlias,
                    child: page.thumbnail == null
                        ? Icon(Icons.description_outlined, color: colors.muted)
                        : Image.memory(page.thumbnail!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Page ${page.number}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: page.removed ? colors.muted : colors.ink,
                    decoration: page.removed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              AppIconButton(
                icon: Icons.rotate_90_degrees_cw_outlined,
                onPressed: page.removed
                    ? null
                    : () => setState(() {
                          page.rotation = (page.rotation + 90) % 360;
                          _changed = true;
                        }),
              ),
              AppIconButton(
                icon: page.removed ? Icons.undo : Icons.delete_outline,
                tint: page.removed ? null : colors.danger,
                onPressed: () => setState(() {
                  page.removed = !page.removed;
                  _changed = true;
                }),
              ),
              ReorderableDragStartListener(
                index: index,
                child: SizedBox(
                  width: 34,
                  height: 44,
                  child: Icon(Icons.drag_handle, size: 20, color: colors.muted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final kept = _pages.where((page) => !page.removed).toList();
    final edit = PageEdit(
      order: kept.map((page) => page.number).toList(),
      rotations: {
        for (final page in kept)
          if (page.rotation != 0) page.number: page.rotation,
      },
    );

    setState(() => _saving = true);
    try {
      await ref.read(libraryProvider.notifier).applyPageEdit(widget.document, edit);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        await notify(
          context,
          title: 'Could not save',
          message: 'The document was left unchanged.',
        );
      }
    }
  }
}
