import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.leading,
    this.footer,
    this.largeTitle = true,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? leading;
  final Widget? footer;
  final bool largeTitle;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(leading == null ? 20 : 4, 8, 12, largeTitle ? 4 : 8),
              child: Row(
                children: [
                  ?leading,
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: largeTitle ? TextAlign.start : TextAlign.center,
                      style: TextStyle(
                        fontSize: largeTitle ? 30 : 17,
                        fontWeight: largeTitle ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: largeTitle ? -0.5 : 0,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  ...actions,
                  if (leading != null && actions.isEmpty) const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(child: child),
            if (footer != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border(top: BorderSide(color: colors.hairline)),
                ),
                child: SafeArea(top: false, child: footer!),
              ),
          ],
        ),
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.arrow_back_ios_new,
      onPressed: () => Navigator.pop(context),
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.icon, this.onPressed, this.tint});

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final enabled = onPressed != null;

    return PressScale(
      onTap: onPressed,
      scale: 0.86,
      child: SizedBox(
        width: 44,
        height: 44,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: enabled ? 1 : 0.45,
          child: Icon(icon, size: 21, color: tint ?? colors.ink),
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.plain = false,
    this.danger = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool plain;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final enabled = onPressed != null && !busy;

    final fill = plain ? Colors.transparent : (danger ? colors.danger : colors.accent);
    final text = plain ? (danger ? colors.danger : colors.ink) : colors.onAccent;

    return PressScale(
      onTap: enabled ? onPressed : null,
      scale: 0.975,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radiusMedium),
            border: plain ? Border.all(color: colors.hairline) : null,
            boxShadow: plain || !enabled
                ? null
                : [
                    BoxShadow(
                      color: fill.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: text),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 19, color: text),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AppRow extends StatefulWidget {
  const AppRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dimmed = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  State<AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<AppRow> {
  bool _held = false;

  void _set(bool value) {
    if (_held == value || widget.onTap == null) return;
    setState(() => _held = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _held ? colors.accent.withValues(alpha: 0.07) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: widget.dimmed ? colors.muted : colors.ink,
                      decoration: widget.dimmed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: colors.muted),
                    ),
                  ],
                ],
              ),
            ),
            ?widget.trailing,
          ],
        ),
      ),
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 48,
        height: 29,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? colors.accent : colors.hairline,
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 23,
            height: 23,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class AppHairline extends StatelessWidget {
  const AppHairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent),
      color: AppTheme.of(context).hairline,
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radiusSmall),
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 19, color: colors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: colors.accent,
              style: TextStyle(fontSize: 16, color: colors.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: colors.muted, fontSize: 16),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(Icons.close, size: 18, color: colors.muted),
            ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.detail,
    this.icon,
    this.action,
  });

  final String title;
  final String detail;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Center(
      child: FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 66,
                  height: 66,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: colors.accent),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: colors.muted),
              ),
              if (action != null) ...[const SizedBox(height: 22), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: AppTheme.of(context).accent),
      ),
    );
  }
}
