import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

/// "Console" is a fixed hand-picked dark palette (not derived from a seed
/// color like the rest of the app's themes), so it's built once here instead
/// of going through [ColorScheme.fromSeed].
const _consoleColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF00D9FF),
  onPrimary: Color(0xFF00131A),
  secondary: Color(0xFF2563EB),
  onSecondary: Color(0xFFDDE0F0),
  tertiary: Color(0xFFA855F7),
  onTertiary: Color(0xFFDDE0F0),
  error: Color(0xFFFF4060),
  onError: Color(0xFFDDE0F0),
  surface: Color(0xFF000000),
  onSurface: Color(0xFFDDE0F0),
  onSurfaceVariant: Color(0xFF777799),
  outline: Color(0xFF272740),
  outlineVariant: Color(0xFF1A1A2E),
  surfaceContainerLowest: Color(0xFF000000),
  surfaceContainerLow: Color(0xFF0C0C14),
  surfaceContainer: Color(0xFF0E0E18),
  surfaceContainerHigh: Color(0xFF111119),
  surfaceContainerHighest: Color(0xFF1E1E30),
  inverseSurface: Color(0xFFDDE0F0),
  onInverseSurface: Color(0xFF000000),
  // Left at their Material3 defaults, the "*Container" roles fall back to the
  // plain accent color itself (e.g. primaryContainer -> primary) while
  // widgets like ListTile's selected state and SegmentedButton independently
  // default their *text* color to that very same accent - background and
  // foreground end up identical (cyan-on-cyan) and the label disappears.
  // Giving each container role its own dim, accent-tinted panel color keeps
  // selected rows/segments legible instead of a solid neon block.
  primaryContainer: Color(0xFF0A2A33),
  onPrimaryContainer: Color(0xFF00D9FF),
  secondaryContainer: Color(0xFF0F1730),
  onSecondaryContainer: Color(0xFFDDE0F0),
  tertiaryContainer: Color(0xFF1F1030),
  onTertiaryContainer: Color(0xFFA855F7),
  errorContainer: Color(0xFF2A0A14),
  onErrorContainer: Color(0xFFFF4060),
);

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  static const _consoleHeadlineFontFamily = "Unbounded";
  static const _consoleBodyFontFamily = "Inter";

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    if (mode == AppThemeMode.console) return _consoleTheme();
    final ColorScheme scheme = lightColorScheme ?? ColorScheme.fromSeed(seedColor: const Color(0xFF0091FF));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light},
    );
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    if (mode == AppThemeMode.console) return _consoleTheme();
    final ColorScheme scheme =
        darkColorScheme ?? ColorScheme.fromSeed(seedColor: const Color(0xFF0091FF), brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mode.trueBlack ? Colors.black : scheme.background,
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light},
    );
  }

  ThemeData _consoleTheme() {
    const scheme = _consoleColorScheme;
    final baseTextTheme = ThemeData(
      brightness: Brightness.dark,
      fontFamily: _consoleBodyFontFamily,
    ).textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: _consoleHeadlineFontFamily),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: _consoleHeadlineFontFamily),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: _consoleHeadlineFontFamily),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: _consoleHeadlineFontFamily, fontWeight: FontWeight.w600),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: _consoleBodyFontFamily,
      textTheme: textTheme,
      cardColor: scheme.surfaceContainerLow,
      dividerColor: scheme.outline,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.console, StatusColors.console},
    );
  }

  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    final bool isDark = switch (mode) {
      AppThemeMode.system => sysDark,
      AppThemeMode.light => false,
      AppThemeMode.dark => true,
      AppThemeMode.black => true,
      AppThemeMode.console => true,
    };
    final def = CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light);
    // final def = CupertinoThemeData(brightness: Brightness.dark);

    // return def;
    final defaultMaterialTheme = isDark ? darkTheme(darkColorScheme) : lightTheme(lightColorScheme);
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(fontFamily: fontFamily),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(fontFamily: fontFamily),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(fontFamily: fontFamily),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(fontFamily: fontFamily),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: fontFamily),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(fontFamily: fontFamily),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: fontFamily),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(fontFamily: fontFamily),
          ).copyWith(),
          barBackgroundColor: def.barBackgroundColor,
          scaffoldBackgroundColor: def.scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
