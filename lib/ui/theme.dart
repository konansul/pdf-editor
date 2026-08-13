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
    background: Color(0xFFF4F6F9),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF17222E),
    muted: Color(0xFF6B7C8F),
    hairline: Color(0xFFE0E6EE),
    accent: Color(0xFF2D465F),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC0453D),
  );

  static const dark = AppColors(
    background: Color(0xFF11181F),
    surface: Color(0xFF1A242F),
    ink: Color(0xFFE9EEF4),
    muted: Color(0xFF8D9BAB),
    hairline: Color(0xFF2A3644),
    accent: Color(0xFF9DBBD9),
    onAccent: Color(0xFF13202B),
    danger: Color(0xFFE87A72),
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
