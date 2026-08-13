import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.hairline,
    required this.accent,
    required this.onAccent,
    required this.danger,
  });

  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color hairline;
  final Color accent;
  final Color onAccent;
  final Color danger;

  static const light = AppColors(
    background: Color(0xFFF8F7FC),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF16132A),
    muted: Color(0xFF7C7796),
    hairline: Color(0xFFE6E3F0),
    accent: Color(0xFF5B2FE0),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFD23B3B),
  );

  static const dark = AppColors(
    background: Color(0xFF0D0A1C),
    surface: Color(0xFF181433),
    ink: Color(0xFFECEAF7),
    muted: Color(0xFF8A85A8),
    hairline: Color(0xFF272147),
    accent: Color(0xFFB472FC),
    onAccent: Color(0xFF150E3F),
    danger: Color(0xFFF06B6B),
  );
}

class AppTheme extends InheritedWidget {
  const AppTheme({super.key, required this.colors, required super.child});

  final AppColors colors;

  static AppColors of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    return theme?.colors ?? AppColors.light;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => colors != oldWidget.colors;
}

const radiusSmall = 10.0;
const radiusMedium = 16.0;
const radiusLarge = 22.0;

ThemeData buildTheme(AppColors colors, Brightness brightness) {
  final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();

  return base.copyWith(
    scaffoldBackgroundColor: colors.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
    colorScheme: base.colorScheme.copyWith(
      primary: colors.accent,
      onPrimary: colors.onAccent,
      surface: colors.surface,
      error: colors.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: colors.ink,
      displayColor: colors.ink,
      fontFamily: '.SF Pro Text',
    ),
    dividerColor: colors.hairline,
    iconTheme: IconThemeData(color: colors.ink),
  );
}
