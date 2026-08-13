import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../providers.dart';
import '../ui/components.dart';
import '../widgets/document_tile.dart';

class PickDocumentScreen extends ConsumerWidget {
  const PickDocumentScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);

    return AppScaffold(
      title: title,
      largeTitle: false,
      leading: const AppBackButton(),
      child: library.when(
        loading: () => const AppSpinner(),
        error: (error, stack) => AppEmptyState(title: 'Could not load', detail: '$error'),
        data: (documents) {
          if (documents.isEmpty) {
            return const AppEmptyState(
              title: 'Your library is empty',
              detail: 'Scan or import a document first.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            itemCount: documents.length,
            separatorBuilder: (context, index) => const AppHairline(indent: 76),
            itemBuilder: (context, index) {
              final document = documents[index];
              return DocumentTile(
                document: document,
                onTap: () => Navigator.pop(context, document),
              );
            },
          );
        },
      ),
    );
  }
}

Future<Document?> pickDocument(BuildContext context, String title) {
  return Navigator.of(context).push<Document>(
    MaterialPageRoute(builder: (context) => PickDocumentScreen(title: title)),
  );
}
