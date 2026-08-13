import 'package:flutter/material.dart';

import '../ui/motion.dart';
import '../ui/theme.dart';
import 'documents_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _pages = [DocumentsScreen(), ToolsScreen(), SettingsScreen()];

  static const _tabs = [
    (Icons.description_outlined, Icons.description, 'Documents'),
    (Icons.handyman_outlined, Icons.handyman, 'Tools'),
    (Icons.tune_outlined, Icons.tune, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                for (var index = 0; index < _tabs.length; index++)
                  Expanded(
                    child: _Tab(
                      tab: _tabs[index],
                      selected: _index == index,
                      onTap: () => setState(() => _index = index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.tab, required this.selected, required this.onTap});

  final (IconData, IconData, String) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final colour = selected ? colors.accent : colors.muted;

    return PressScale(
      onTap: onTap,
      scale: 0.9,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.12 : 1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected ? tab.$2 : tab.$1,
                key: ValueKey(selected),
                size: 23,
                color: colour,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: colour,
            ),
            child: Text(tab.$3),
          ),
        ],
      ),
    );
  }
}
