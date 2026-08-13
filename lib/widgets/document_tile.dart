import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/document.dart';
import '../ui/components.dart';
import '../ui/theme.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.onTap,
    this.onMore,
    this.badge,
  });

  final Document document;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AppRow(
      title: document.name,
      subtitle:
          '${_pages(document.pageCount)} · ${_size(document.byteSize)} · ${_date(document.updatedAt)}',
      leading: _Thumbnail(path: document.thumbnailPath),
      onTap: onTap,
      trailing: badge != null
          ? _Badge(label: badge!)
          : onMore == null
              ? null
              : AppIconButton(icon: Icons.more_horiz, onPressed: onMore),
    );
  }

  String _pages(int count) => count == 1 ? '1 page' : '$count pages';

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _date(DateTime value) {
    final now = DateTime.now();
    final sameDay = now.year == value.year && now.month == value.month && now.day == value.day;
    return sameDay ? DateFormat.Hm().format(value) : DateFormat.MMMd().format(value);
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    final placeholder = Container(
      width: 42,
      height: 56,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.hairline),
      ),
      child: Icon(Icons.description_outlined, size: 20, color: colors.muted),
    );

    final file = path == null ? null : File(path!);
    if (file == null || !file.existsSync()) return placeholder;

    return Container(
      width: 42,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.onAccent),
      ),
    );
  }
}
