import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'services/analytics_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.instance.start();
  runApp(const ProviderScope(child: PdfEditorApp()));
}

class PdfEditorApp extends ConsumerWidget {
  const PdfEditorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp(
      title: 'PDF Editor',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: buildTheme(AppColors.light, Brightness.light),
      darkTheme: buildTheme(AppColors.dark, Brightness.dark),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AppTheme(
          colors: dark ? AppColors.dark : AppColors.light,
          child: child ?? const SizedBox.shrink(),
        );
      },
      navigatorObservers: [
        if (AnalyticsService.instance.observer != null)
          AnalyticsService.instance.observer!,
      ],
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
