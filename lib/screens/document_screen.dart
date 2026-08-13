import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';

import '../models/document.dart';
import '../providers.dart';
import '../ui/components.dart';
import '../ui/sheets.dart';
import '../ui/theme.dart';
import 'convert_screen.dart';
import 'pages_screen.dart';
import 'text_screen.dart';
import 'tools_screen.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key, required this.document});

  final Document document;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  PdfControllerPinch? _controller;
  late Document _document;
  int _page = 1;
  bool _loading = true;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final file = File(_document.filePath);
    if (!await file.exists()) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failure = 'missing';
        });
      }
      return;
    }

    try {
      final document = await PdfDocument.openFile(file.path);
      final controller = PdfControllerPinch(document: Future.value(document));
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failure = 'unreadable';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final ready = _controller != null;

    return AppScaffold(
      title: _document.name,
      largeTitle: false,
      leading: const AppBackButton(),
      actions: [
        AppIconButton(icon: Icons.ios_share, onPressed: ready ? _share : null),
        AppIconButton(icon: Icons.more_horiz, onPressed: _showMenu),
      ],
      footer: ready
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Page $_page of ${_document.pageCount}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.muted),
              ),
            )
          : null,
      child: _body(colors),
    );
  }

  Widget _body(AppColors colors) {
    if (_loading) return const AppSpinner();

    if (_failure == 'missing') {
      return const AppEmptyState(
        title: 'File is missing',
        detail: 'The PDF behind this entry is no longer on the device.',
      );
    }

    if (_failure != null || _controller == null) {
      return const AppEmptyState(
        title: 'Could not open this file',
        detail: 'It is not a readable PDF.',
      );
    }

    return PdfViewPinch(
      controller: _controller!,
      onPageChanged: (page) => setState(() => _page = page),
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) => const AppSpinner(),
        pageLoaderBuilder: (context) => const AppSpinner(),
        errorBuilder: (context, error) => const AppEmptyState(
          title: 'Could not open this file',
          detail: 'It is not a readable PDF.',
        ),
      ),
      backgroundDecoration: BoxDecoration(color: colors.background),
    );
  }

  Future<void> _showMenu() async {
    final choice = await chooseOption(
      context,
      title: _document.name,
      options: const [
        SheetOption(value: 'text', label: 'Extract text', icon: Icons.text_fields),
        SheetOption(
          value: 'convert',
          label: 'Convert',
          detail: 'Images, Word, PowerPoint or plain text',
          icon: Icons.swap_horiz,
        ),
        SheetOption(value: 'pages', label: 'Reorder pages', icon: Icons.swap_vert_circle_outlined),
        SheetOption(value: 'rename', label: 'Rename', icon: Icons.edit_outlined),
        SheetOption(
          value: 'delete',
          label: 'Delete',
          icon: Icons.delete_outline,
          destructive: true,
        ),
      ],
    );

    if (choice == 'text') await _extractText();
    if (choice == 'convert') await _convert();
    if (choice == 'pages') await _editPages();
    if (choice == 'rename') await _rename();
    if (choice == 'delete') await _delete();
  }

  Future<void> _extractText() async {
    pushScreen(context, TextScreen(document: _document));
  }

  Future<void> _convert() async {
    final choice = await chooseOption(
      context,
      title: 'Convert',
      options: [
        for (final format in ExportFormat.values)
          SheetOption(
            value: format.name,
            label: format.title,
            detail: format.detail,
            icon: format.icon,
          ),
      ],
    );

    if (choice == null || !mounted) return;

    final format = ExportFormat.values.firstWhere((value) => value.name == choice);

    pushScreen(context, ConvertScreen(document: _document, format: format));
  }

  Future<void> _share() async {
    final bytes = await File(_document.filePath).readAsBytes();
    await Printing.sharePdf(bytes: bytes, filename: '${_document.name}.pdf');
  }

  Future<void> _editPages() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => PagesScreen(document: _document)),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _rename() async {
    final name = await askForText(
      context,
      title: 'Rename',
      initial: _document.name,
      action: 'Save',
    );

    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == _document.name) return;

    await ref.read(libraryProvider.notifier).rename(_document, trimmed);
    setState(() => _document = _document.copyWith(name: trimmed));
  }

  Future<void> _delete() async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this document?',
      message: '"${_document.name}" will be removed from this device.',
      action: 'Delete',
      destructive: true,
    );

    if (!confirmed) return;
    await ref.read(libraryProvider.notifier).delete(_document);
    if (mounted) Navigator.pop(context);
  }
}
