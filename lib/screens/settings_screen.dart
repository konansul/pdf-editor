import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';
import '../ui/components.dart';
import '../ui/sheets.dart';
import '../ui/theme.dart';

const _privacyUrl = 'https://konansul.github.io/pdf-editor-legal/privacy.html';
const _termsUrl = 'https://konansul.github.io/pdf-editor-legal/terms.html';
const _supportEmail = 'konansulx@gmail.com';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.of(context);
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return AppScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 32),
        children: [
          const SizedBox(height: 4),
          const AppHairline(indent: 20),
          AppRow(
            title: 'Appearance',
            subtitle: _appearanceLabel(mode),
            onTap: () => _chooseAppearance(context, ref, mode),
            trailing: Icon(Icons.chevron_right, size: 20, color: colors.muted),
          ),
          const AppHairline(indent: 20),
          AppRow(
            title: 'Privacy Policy',
            onTap: () => _open(context, Uri.parse(_privacyUrl)),
            trailing: Icon(Icons.north_east, size: 18, color: colors.muted),
          ),
          const AppHairline(indent: 20),
          AppRow(
            title: 'Terms of Use',
            onTap: () => _open(context, Uri.parse(_termsUrl)),
            trailing: Icon(Icons.north_east, size: 18, color: colors.muted),
          ),
          const AppHairline(indent: 20),
          AppRow(
            title: 'Contact',
            subtitle: _supportEmail,
            onTap: () => _open(
              context,
              Uri(scheme: 'mailto', path: _supportEmail, queryParameters: {'subject': 'PDF Editor'}),
            ),
            trailing: Icon(Icons.north_east, size: 18, color: colors.muted),
          ),
          const AppHairline(indent: 20),
          AppRow(
            title: 'Show the intro again',
            onTap: () => ref.read(onboardingProvider.notifier).reset(),
            trailing: Icon(Icons.chevron_right, size: 20, color: colors.muted),
          ),
          const AppHairline(indent: 20),
          AppRow(
            title: 'About PDF Editor',
            subtitle: 'Version 1.0',
            onTap: () => notify(
              context,
              title: 'PDF Editor',
              message: 'A PDF toolkit that runs on your device. Scan, merge, reorder, split, '
                  'compress and lock documents without sending them anywhere.',
            ),
            trailing: Icon(Icons.chevron_right, size: 20, color: colors.muted),
          ),
          const AppHairline(indent: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Text(
              'PDF Editor works entirely offline. Nothing you scan or import leaves this device, '
              'there is no account to create, and no analytics follow you around.',
              style: TextStyle(fontSize: 13, height: 1.45, color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }

  String _appearanceLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'Match device',
      };

  Future<void> _chooseAppearance(BuildContext context, WidgetRef ref, ThemeMode current) async {
    final choice = await chooseOption(
      context,
      title: 'Appearance',
      options: const [
        SheetOption(
          value: 'system',
          label: 'Match device',
          detail: 'Follow the light or dark setting on this phone',
          icon: Icons.brightness_auto_outlined,
        ),
        SheetOption(
          value: 'light',
          label: 'Light',
          detail: 'Always use the light theme',
          icon: Icons.light_mode_outlined,
        ),
        SheetOption(
          value: 'dark',
          label: 'Dark',
          detail: 'Always use the dark theme',
          icon: Icons.dark_mode_outlined,
        ),
      ],
    );

    if (choice == null) return;

    final selected = switch (choice) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    if (selected != current) {
      await ref.read(themeModeProvider.notifier).select(selected);
    }
  }

  Future<void> _open(BuildContext context, Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      await notify(
        context,
        title: 'Could not open the link',
        message: url.toString(),
      );
    }
  }

}
