import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/document.dart';
import '../providers.dart';
import '../ui/components.dart';
import '../ui/sheets.dart';
import '../ui/theme.dart';
import '../widgets/document_tile.dart';

class MergeScreen extends ConsumerStatefulWidget {
  const MergeScreen({super.key});

  @override
  ConsumerState<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends ConsumerState<MergeScreen> {
  final _selected = <String>[];
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final library = ref.watch(libraryProvider);

    return AppScaffold(
      title: 'Merge',
      largeTitle: false,
      leading: const AppBackButton(),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selected.length < 2
                  ? 'Pick two or more. They merge in the order you tap them.'
                  : '${_selected.length} selected',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Merge',
              busy: _busy,
              onPressed: _selected.length >= 2 ? _merge : null,
            ),
          ],
        ),
      ),
      child: library.when(
        loading: () => const AppSpinner(),
        error: (error, stack) => AppEmptyState(title: 'Could not load', detail: '$error'),
        data: (documents) {
          if (documents.length < 2) {
            return const AppEmptyState(
              title: 'Not enough documents',
              detail: 'Merging needs at least two documents in your library.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            itemCount: documents.length,
            separatorBuilder: (context, index) => const AppHairline(indent: 76),
            itemBuilder: (context, index) {
              final document = documents[index];
              final position = _selected.indexOf(document.id);

              return DocumentTile(
                document: document,
                onTap: () => _toggle(document),
                badge: position >= 0 ? '${position + 1}' : null,
              );
            },
          );
        },
      ),
    );
  }

  void _toggle(Document document) {
    setState(() {
      if (_selected.contains(document.id)) {
        _selected.remove(document.id);
      } else {
        _selected.add(document.id);
      }
    });
  }

  Future<void> _merge() async {
    final documents = ref.read(libraryProvider).value ?? [];
    final ordered =
        _selected.map((id) => documents.firstWhere((document) => document.id == id)).toList();

    final now = DateTime.now();
    final name = 'Merged ${DateFormat.yMMMd().format(now)} ${DateFormat.Hm().format(now)}';

    setState(() => _busy = true);
    try {
      await ref.read(libraryProvider.notifier).merge(ordered, name);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        await notify(
          context,
          title: 'Merge failed',
          message: 'Those documents could not be combined.',
        );
      }
    }
  }
}
