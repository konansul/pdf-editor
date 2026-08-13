import 'package:flutter/material.dart';

import 'components.dart';
import 'theme.dart';

class SheetOption {
  const SheetOption({
    required this.value,
    required this.label,
    this.detail,
    this.icon,
    this.destructive = false,
  });

  final String value;
  final String label;
  final String? detail;
  final IconData? icon;
  final bool destructive;
}

Future<T?> _present<T>(BuildContext context, Widget Function(BuildContext) builder) {
  final colors = AppTheme.of(context);

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: colors.background,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(top: false, child: builder(context)),
    ),
  );
}

Widget _grabber(BuildContext context) {
  return Container(
    width: 36,
    height: 4,
    margin: const EdgeInsets.only(top: 10, bottom: 6),
    decoration: BoxDecoration(
      color: AppTheme.of(context).hairline,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _heading(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppTheme.of(context).ink,
      ),
    ),
  );
}

Future<String?> chooseOption(
  BuildContext context, {
  required String title,
  required List<SheetOption> options,
}) {
  return _present<String>(context, (context) {
    final colors = AppTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(context),
        _heading(context, title),
        const SizedBox(height: 6),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options) ...[
                  const AppHairline(indent: 20),
                  AppRow(
                    title: option.label,
                    subtitle: option.detail,
                    leading: option.icon == null
                        ? null
                        : Icon(
                            option.icon,
                            size: 22,
                            color: option.destructive ? colors.danger : colors.ink,
                          ),
                    onTap: () => Navigator.pop(context, option.value),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: AppButton(
            label: 'Cancel',
            plain: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  });
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final result = await _present<bool>(context, (context) {
    final colors = AppTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(context),
        _heading(context, title),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Text(
            message,
            style: TextStyle(fontSize: 15, height: 1.4, color: colors.muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            children: [
              AppButton(
                label: action,
                danger: destructive,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Cancel',
                plain: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ],
    );
  });

  return result ?? false;
}

Future<void> notify(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  await _present<void>(context, (context) {
    final colors = AppTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(context),
        _heading(context, title),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Text(
            message,
            style: TextStyle(fontSize: 15, height: 1.4, color: colors.muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: AppButton(label: 'OK', onPressed: () => Navigator.pop(context)),
        ),
      ],
    );
  });
}

Future<String?> askForText(
  BuildContext context, {
  required String title,
  required String initial,
  required String action,
  String? hint,
  bool obscure = false,
}) {
  final controller = TextEditingController(text: initial);
  controller.selection = TextSelection(baseOffset: 0, extentOffset: initial.length);

  return _present<String>(context, (context) {
    final colors = AppTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(context),
        _heading(context, title),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radiusSmall),
              border: Border.all(color: colors.hairline),
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              obscureText: obscure,
              cursorColor: colors.accent,
              style: TextStyle(fontSize: 16, color: colors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: colors.muted),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            children: [
              AppButton(
                label: action,
                onPressed: () => Navigator.pop(context, controller.text),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Cancel',
                plain: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  });
}
