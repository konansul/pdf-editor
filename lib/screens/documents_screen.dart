import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/document.dart';
import '../models/folder.dart';
import '../providers.dart';
import '../services/scanner_service.dart';
import '../ui/components.dart';
import '../ui/motion.dart';
import '../ui/sheets.dart';
import '../ui/theme.dart';
import '../widgets/document_tile.dart';
import 'document_screen.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) => const LibraryScreen(folder: null);
}

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key, required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) => LibraryScreen(folder: folder);
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, required this.folder});

  final Folder? folder;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  late Folder? _folder = widget.folder;
  bool _busy = false;

  bool get _isRoot => _folder == null;

  String? get _folderId => _folder?.id;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _folder?.name ?? 'Documents',
      largeTitle: _isRoot,
      leading: _isRoot ? null : const AppBackButton(),
      actions: [
        if (_isRoot)
          AppIconButton(icon: Icons.swap_vert, onPressed: _busy ? null : _showSortMenu)
        else
          AppIconButton(icon: Icons.more_horiz, onPressed: _busy ? null : _showFolderMenu),
        AppIconButton(icon: Icons.add, onPressed: _busy ? null : _showCreateMenu),
      ],
      child: Column(
        children: [
          if (_isRoot)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: AppSearchField(
                controller: _searchController,
                hint: 'Search documents',
                onChanged: _onSearch,
              ),
            ),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _list() {
    final library = ref.watch(libraryProvider);
    final searching = _isRoot && ref.watch(searchQueryProvider).trim().isNotEmpty;

    return library.when(
      loading: () => const AppSpinner(),
      error: (error, stack) => AppEmptyState(
        title: 'Could not open your library',
        detail: '$error',
      ),
      data: (all) {
        final documents = searching
            ? all
            : all.where((document) => document.folderId == _folderId).toList();
        final folders = _isRoot && !searching
            ? (ref.watch(foldersProvider).value ?? const <Folder>[])
            : const <Folder>[];

        if (documents.isEmpty && folders.isEmpty) return _empty(searching);

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: folders.length + documents.length,
          separatorBuilder: (context, index) => const AppHairline(indent: 76),
          itemBuilder: (context, index) {
            if (index < folders.length) {
              final folder = folders[index];
              final count = all.where((document) => document.folderId == folder.id).length;
              return FadeSlideIn(
                delay: FadeSlideIn.stagger(index),
                child: _FolderRow(
                  folder: folder,
                  count: count,
                  onTap: () => _openFolder(folder),
                ),
              );
            }

            final document = documents[index - folders.length];
            return FadeSlideIn(
              delay: FadeSlideIn.stagger(index),
              child: DocumentTile(
                document: document,
                onTap: () => _open(document),
                onMore: () => _showDocumentMenu(document),
              ),
            );
          },
        );
      },
    );
  }

  Widget _empty(bool searching) {
    if (searching) {
      return const AppEmptyState(
        title: 'Nothing found',
        detail: 'Try a different name.',
        icon: Icons.search_off,
      );
    }
    if (!_isRoot) {
      return const AppEmptyState(
        title: 'This folder is empty',
        detail: 'Add a scan, or move documents in from the library.',
        icon: Icons.folder_open_outlined,
      );
    }
    return AppEmptyState(
      title: 'No documents yet',
      detail: 'Scan a page or import a PDF. Everything stays on this device.',
      icon: Icons.document_scanner_outlined,
      action: SizedBox(
        width: 200,
        child: AppButton(label: 'Scan a page', icon: Icons.add, onPressed: _scan),
      ),
    );
  }

  void _onSearch(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    setState(() {});
  }

  Future<void> _openFolder(Folder folder) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => FolderScreen(folder: folder)),
    );
    ref.invalidate(libraryProvider);
    ref.invalidate(foldersProvider);
  }

  Future<void> _showSortMenu() async {
    final choice = await chooseOption(
      context,
      title: 'Sort by',
      options: const [
        SheetOption(value: 'newest', label: 'Newest first', icon: Icons.schedule),
        SheetOption(value: 'oldest', label: 'Oldest first', icon: Icons.history),
        SheetOption(value: 'name', label: 'Name', icon: Icons.sort_by_alpha),
      ],
    );

    final sort = switch (choice) {
      'newest' => DocumentSort.newest,
      'oldest' => DocumentSort.oldest,
      'name' => DocumentSort.name,
      _ => null,
    };
    if (sort != null) ref.read(sortProvider.notifier).state = sort;
  }

  Future<void> _showCreateMenu() async {
    final choice = await chooseOption(
      context,
      title: _isRoot ? 'New' : 'Add to ${_folder!.name}',
      options: [
        const SheetOption(
          value: 'scan',
          label: 'Scan with camera',
          detail: 'Detects page edges automatically',
          icon: Icons.document_scanner_outlined,
        ),
        const SheetOption(
          value: 'photos',
          label: 'Build from photos',
          detail: 'Each photo becomes a page',
          icon: Icons.photo_library_outlined,
        ),
        const SheetOption(
          value: 'import',
          label: 'Import a PDF',
          detail: 'From Files or another app',
          icon: Icons.folder_open_outlined,
        ),
        if (_isRoot)
          const SheetOption(
            value: 'folder',
            label: 'New folder',
            detail: 'Group documents together',
            icon: Icons.create_new_folder_outlined,
          ),
      ],
    );

    if (choice == 'scan') await _scan();
    if (choice == 'photos') await _importPhotos();
    if (choice == 'import') await _importPdf();
    if (choice == 'folder') await _createFolder();
  }

  Future<void> _showFolderMenu() async {
    final folder = _folder;
    if (folder == null) return;

    final choice = await chooseOption(
      context,
      title: folder.name,
      options: const [
        SheetOption(value: 'rename', label: 'Rename folder', icon: Icons.edit_outlined),
        SheetOption(
          value: 'delete',
          label: 'Delete folder',
          detail: 'Documents move back to the library',
          icon: Icons.delete_outline,
          destructive: true,
        ),
      ],
    );

    if (choice == 'rename') await _renameFolder(folder);
    if (choice == 'delete') await _deleteFolder(folder);
  }

  Future<void> _showDocumentMenu(Document document) async {
    final choice = await chooseOption(
      context,
      title: document.name,
      options: [
        const SheetOption(value: 'rename', label: 'Rename', icon: Icons.edit_outlined),
        SheetOption(
          value: 'move',
          label: document.folderId == null ? 'Move to folder' : 'Move',
          icon: Icons.drive_file_move_outline,
        ),
        const SheetOption(
          value: 'delete',
          label: 'Delete',
          icon: Icons.delete_outline,
          destructive: true,
        ),
      ],
    );

    if (choice == 'rename') await _rename(document);
    if (choice == 'move') await _move(document);
    if (choice == 'delete') await _delete(document);
  }

  Future<void> _createFolder() async {
    final name = await askForText(
      context,
      title: 'New folder',
      initial: '',
      action: 'Create',
      hint: 'Folder name',
    );

    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await ref.read(foldersProvider.notifier).create(trimmed);
  }

  Future<void> _renameFolder(Folder folder) async {
    final name = await askForText(
      context,
      title: 'Rename folder',
      initial: folder.name,
      action: 'Save',
    );

    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == folder.name) return;
    await ref.read(foldersProvider.notifier).rename(folder, trimmed);
    if (mounted) {
      setState(() {
        _folder = Folder(id: folder.id, name: trimmed, createdAt: folder.createdAt);
      });
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this folder?',
      message: 'The documents inside "${folder.name}" stay in your library.',
      action: 'Delete',
      destructive: true,
    );

    if (!confirmed) return;
    await ref.read(foldersProvider.notifier).delete(folder);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _move(Document document) async {
    final folders = ref.read(foldersProvider).value ?? const <Folder>[];

    final choice = await chooseOption(
      context,
      title: 'Move "${document.name}"',
      options: [
        if (document.folderId != null)
          const SheetOption(
            value: '',
            label: 'Library',
            detail: 'Out of every folder',
            icon: Icons.inbox_outlined,
          ),
        for (final folder in folders)
          if (folder.id != document.folderId)
            SheetOption(value: folder.id, label: folder.name, icon: Icons.folder_outlined),
        const SheetOption(
          value: 'new',
          label: 'New folder',
          icon: Icons.create_new_folder_outlined,
        ),
      ],
    );

    if (choice == null || !mounted) return;

    if (choice == 'new') {
      final name = await askForText(
        context,
        title: 'New folder',
        initial: '',
        action: 'Create',
        hint: 'Folder name',
      );
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      final folder = await ref.read(foldersProvider.notifier).create(trimmed);
      await ref.read(libraryProvider.notifier).move(document, folder.id);
      return;
    }

    await ref.read(libraryProvider.notifier).move(document, choice.isEmpty ? null : choice);
  }

  Future<void> _scan() async {
    setState(() => _busy = true);
    try {
      await ref.read(libraryProvider.notifier).scan(folderId: _folderId);
    } on ScannerCancelled {
      return;
    } on ScannerPermissionBlocked {
      await _offerSettings();
    } on ScannerPermissionDenied {
      await _report(
        'Camera access needed',
        'Scanning uses the camera to find the edges of a page. Tap Scan a page again to allow it.',
      );
    } on ScannerFailed catch (error) {
      await _report('Scanning failed', error.reason);
    } catch (error) {
      await _report('Scanning failed', 'Nothing was added to your library.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(libraryProvider.notifier).importImages(
            picked.map((file) => File(file.path)).toList(),
            folderId: _folderId,
          );
    } catch (error) {
      await _report('Could not build a PDF', 'Those photos could not be used.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(libraryProvider.notifier).importPdf(File(path), folderId: _folderId);
    } catch (error) {
      await _report('Not a readable PDF', 'That file could not be imported.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(Document document) async {
    final name = await askForText(
      context,
      title: 'Rename',
      initial: document.name,
      action: 'Save',
    );

    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == document.name) return;
    await ref.read(libraryProvider.notifier).rename(document, trimmed);
  }

  Future<void> _delete(Document document) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this document?',
      message: '"${document.name}" will be removed from this device.',
      action: 'Delete',
      destructive: true,
    );

    if (!confirmed) return;
    await ref.read(libraryProvider.notifier).delete(document);
  }

  Future<void> _open(Document document) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DocumentScreen(document: document)),
    );
    ref.invalidate(libraryProvider);
  }

  Future<void> _offerSettings() async {
    if (!mounted) return;
    final go = await confirmAction(
      context,
      title: 'Camera is turned off',
      message: 'Scanning needs the camera, and permission was refused earlier. '
          'Turn it back on in Settings, under Privacy or under this app.',
      action: 'Open Settings',
    );
    if (go) await const ScannerService().openSettings();
  }

  Future<void> _report(String title, String message) async {
    if (!mounted) return;
    await notify(context, title: title, message: message);
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.folder, required this.count, required this.onTap});

  final Folder folder;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return AppRow(
      title: folder.name,
      subtitle: count == 1 ? '1 document' : '$count documents',
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        child: Icon(Icons.folder_rounded, size: 22, color: colors.accent),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: colors.muted),
    );
  }
}
