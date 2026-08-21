import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../providers.dart';
import '../services/analytics_service.dart';
import '../ui/components.dart';
import '../ui/motion.dart';
import '../ui/sheets.dart';
import '../ui/theme.dart';
import 'convert_screen.dart';
import 'merge_screen.dart';
import 'pages_screen.dart';
import 'pick_document_screen.dart';
import 'split_screen.dart';
import 'text_screen.dart';

class Tool {
  const Tool({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String id;
  final String title;
  final String detail;
  final IconData icon;
}

class ToolSection {
  const ToolSection({required this.title, required this.tools});

  final String title;
  final List<Tool> tools;
}

const toolSections = [
  ToolSection(
    title: 'Organise',
    tools: [
      Tool(
        id: 'merge',
        title: 'Merge',
        detail: 'Combine several documents into one',
        icon: Icons.library_add_outlined,
      ),
      Tool(
        id: 'pages',
        title: 'Reorder pages',
        detail: 'Move, rotate or delete pages',
        icon: Icons.swap_vert_circle_outlined,
      ),
      Tool(
        id: 'split',
        title: 'Split',
        detail: 'Pull pages out into a new document',
        icon: Icons.content_cut,
      ),
    ],
  ),
  ToolSection(
    title: 'Optimise',
    tools: [
      Tool(
        id: 'compress',
        title: 'Compress',
        detail: 'Make a document smaller to send',
        icon: Icons.compress,
      ),
    ],
  ),
  ToolSection(
    title: 'Convert',
    tools: [
      Tool(
        id: 'text',
        title: 'Extract text',
        detail: 'Read the words off the page',
        icon: Icons.text_fields,
      ),
      Tool(
        id: 'images',
        title: 'PDF to images',
        detail: 'A JPEG for every page',
        icon: Icons.photo_library_outlined,
      ),
      Tool(
        id: 'long-image',
        title: 'PDF to one long image',
        detail: 'Every page stacked into one JPEG',
        icon: Icons.view_day_outlined,
      ),
      Tool(
        id: 'word',
        title: 'PDF to Word',
        detail: 'Recognised text as .docx',
        icon: Icons.description_outlined,
      ),
      Tool(
        id: 'slides',
        title: 'PDF to PowerPoint',
        detail: 'One page per slide',
        icon: Icons.slideshow_outlined,
      ),
      Tool(
        id: 'text-file',
        title: 'PDF to text file',
        detail: 'Recognised text as .txt',
        icon: Icons.notes_outlined,
      ),
    ],
  ),
];

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.of(context);

    return AppScaffold(
      title: 'Tools',
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 28),
        children: [
          for (final (sectionIndex, section) in toolSections.indexed) ...[
            FadeSlideIn(
              delay: FadeSlideIn.stagger(sectionIndex * 2),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  section.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: colors.muted,
                  ),
                ),
              ),
            ),
            for (final tool in section.tools) ...[
              const AppHairline(indent: 20),
              AppRow(
                title: tool.title,
                subtitle: tool.detail,
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(radiusSmall),
                    border: Border.all(color: colors.hairline),
                  ),
                  child: Icon(tool.icon, size: 21, color: colors.ink),
                ),
                trailing: Icon(Icons.chevron_right, size: 20, color: colors.muted),
                onTap: () => _open(context, ref, tool),
              ),
            ],
            const AppHairline(indent: 20),
          ],
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Tool tool) async {
    if (tool.id == 'merge') {
      pushScreen(context, const MergeScreen());
      return;
    }

    final document = await pickDocument(context, tool.title);
    if (document == null || !context.mounted) return;

    unawaited(AnalyticsService.instance.toolUsed(tool.id));

    switch (tool.id) {
      case 'pages':
        pushScreen(context, PagesScreen(document: document));
      case 'split':
        pushScreen(context, SplitScreen(document: document));
      case 'compress':
        await compressDocument(context, ref, document);
      case 'text':
        pushScreen(context, TextScreen(document: document));
      case 'images':
        pushScreen(context, ConvertScreen(document: document, format: ExportFormat.images));
      case 'long-image':
        pushScreen(context, ConvertScreen(document: document, format: ExportFormat.longImage));
      case 'word':
        pushScreen(context, ConvertScreen(document: document, format: ExportFormat.word));
      case 'slides':
        pushScreen(context, ConvertScreen(document: document, format: ExportFormat.slides));
      case 'text-file':
        pushScreen(context, ConvertScreen(document: document, format: ExportFormat.text));
    }
  }
}

void pushScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => screen));
}

Future<void> compressDocument(BuildContext context, WidgetRef ref, Document document) async {
  try {
    final saved = await ref.read(libraryProvider.notifier).compress(document);
    if (!context.mounted) return;
    await notify(
      context,
      title: saved > 0 ? 'Compressed' : 'Already small',
      message: saved > 0
          ? 'Saved ${(saved / 1024).round()} KB.'
          : 'This document was already as small as it gets.',
    );
  } catch (error) {
    if (context.mounted) {
      await notify(
        context,
        title: 'Could not compress',
        message: 'The document was left unchanged.',
      );
    }
  }
}

