import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(const ProviderScope(child: PdfEditorApp()));
}

class PdfEditorApp extends StatelessWidget {
  const PdfEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Editor',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(AppColors.light, Brightness.light),
      darkTheme: buildTheme(AppColors.dark, Brightness.dark),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AppTheme(
          colors: dark ? AppColors.dark : AppColors.light,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _Entry(),
    );
  }
}

class _Entry extends ConsumerWidget {
  const _Entry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(onboardingProvider);
    final colors = AppTheme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (seen) {
        AsyncData(value: true) => const RootScreen(key: ValueKey('root')),
        AsyncData(value: false) => const OnboardingScreen(key: ValueKey('onboarding')),
        _ => ColoredBox(color: colors.background, key: const ValueKey('blank')),
      },
    );
  }
}
