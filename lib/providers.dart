import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/document_database.dart';
import 'data/document_repository.dart';
import 'models/document.dart';
import 'models/folder.dart';
import 'services/export_service.dart';
import 'services/merge_service.dart';
import 'services/ocr_service.dart';
import 'services/page_editor_service.dart';
import 'services/pdf_tools_service.dart';
import 'services/scanner_service.dart';

final databaseProvider = Provider((ref) => DocumentDatabase());

final repositoryProvider = Provider((ref) => DocumentRepository(ref.watch(databaseProvider)));

final scannerProvider = Provider((ref) => const ScannerService());

final mergeProvider = Provider((ref) => const MergeService());

final pageEditorProvider = Provider((ref) => const PageEditorService());

final toolsProvider = Provider((ref) => const PdfToolsService());

final ocrProvider = Provider((ref) => const OcrService());

final exportProvider = Provider((ref) => const ExportService());

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final preferences = await SharedPreferences.getInstance();
    return _decode(preferences.getString(_key));
  }

  Future<void> select(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, mode.name);
    state = AsyncValue.data(mode);
  }

  static ThemeMode _decode(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends AsyncNotifier<bool> {
  static const _key = 'onboarding_seen';

  @override
  Future<bool> build() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key) ?? false;
  }

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, true);
    state = const AsyncValue.data(true);
  }

  Future<void> reset() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, false);
    state = const AsyncValue.data(false);
  }
}

final searchQueryProvider = StateProvider((ref) => '');

final sortProvider = StateProvider((ref) => DocumentSort.newest);

final foldersProvider = AsyncNotifierProvider<FoldersNotifier, List<Folder>>(FoldersNotifier.new);

class FoldersNotifier extends AsyncNotifier<List<Folder>> {
  @override
  Future<List<Folder>> build() => ref.watch(repositoryProvider).loadFolders();

  Future<Folder> create(String name) async {
    final folder = await ref.read(repositoryProvider).createFolder(name);
    ref.invalidateSelf();
    await future;
    return folder;
  }

  Future<void> rename(Folder folder, String name) async {
    await ref.read(repositoryProvider).renameFolder(folder, name);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(Folder folder) async {
    await ref.read(repositoryProvider).deleteFolder(folder);
    ref.invalidateSelf();
    ref.invalidate(libraryProvider);
    await future;
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryNotifier, List<Document>>(LibraryNotifier.new);

class LibraryNotifier extends AsyncNotifier<List<Document>> {
  @override
  Future<List<Document>> build() {
    final query = ref.watch(searchQueryProvider);
    final sort = ref.watch(sortProvider);
    return ref.watch(repositoryProvider).load(query: query, sort: sort);
  }

  Future<void> importPdf(File file, {String? folderId}) async {
    await ref.read(repositoryProvider).importPdf(file, folderId: folderId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> move(Document document, String? folderId) async {
    await ref.read(repositoryProvider).move(document, folderId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> merge(List<Document> documents, String name) async {
    final sources = documents.map((document) => File(document.filePath)).toList();
    final merged = await ref.read(mergeProvider).merge(sources);
    await ref.read(repositoryProvider).importPdf(merged, name: name);
    if (await merged.exists()) await merged.delete();
    ref.invalidateSelf();
    await future;
  }

  Future<void> applyPageEdit(Document document, PageEdit edit) async {
    final edited = await ref.read(pageEditorProvider).apply(File(document.filePath), edit);
    await ref.read(repositoryProvider).replaceFile(document, edited);
    if (await edited.exists()) await edited.delete();
    ref.invalidateSelf();
    await future;
  }

  Future<void> extractPages(Document document, List<int> pages, String name) async {
    final extracted = await ref.read(toolsProvider).extract(File(document.filePath), pages);
    await ref.read(repositoryProvider).importPdf(extracted, name: name);
    if (await extracted.exists()) await extracted.delete();
    ref.invalidateSelf();
    await future;
  }

  Future<int> compress(Document document) async {
    final before = document.byteSize;
    final compressed = await ref.read(toolsProvider).compress(File(document.filePath));
    await ref.read(repositoryProvider).replaceFile(document, compressed);
    final after = await compressed.length();
    if (await compressed.exists()) await compressed.delete();
    ref.invalidateSelf();
    await future;
    return before - after;
  }

  Future<void> importImages(List<File> images, {String? folderId}) async {
    final now = DateTime.now();
    final name = 'Photos ${DateFormat.yMMMd().format(now)} ${DateFormat.Hm().format(now)}';
    await ref.read(repositoryProvider).importImages(images, name: name, folderId: folderId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> scan({String? folderId}) async {
    final file = await ref.read(scannerProvider).scanToPdf();
    await ref.read(repositoryProvider).importPdf(file, name: _scanName(), folderId: folderId);
    ref.invalidateSelf();
    await future;
  }

  String _scanName() {
    final now = DateTime.now();
    final date = DateFormat.yMMMd().format(now);
    final time = DateFormat.Hm().format(now);
    return 'Scan $date $time';
  }

  Future<void> rename(Document document, String name) async {
    await ref.read(repositoryProvider).rename(document, name);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(Document document) async {
    await ref.read(repositoryProvider).delete(document);
    ref.invalidateSelf();
    await future;
  }
}
