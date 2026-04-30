import 'package:flutter/material.dart';

@immutable
class DatabaseTheme extends ThemeExtension<DatabaseTheme> {
  const DatabaseTheme({
    required this.appBarBg,
    required this.panelBg,
    required this.contentBg,
    required this.panelBorder,
    required this.surfaceRaised,
    required this.sourceSelectedBg,
    required this.sourceSelectedText,
    required this.mutedIconBg,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color appBarBg;
  final Color panelBg;
  final Color contentBg;
  final Color panelBorder;
  final Color surfaceRaised;
  final Color sourceSelectedBg;
  final Color sourceSelectedText;
  final Color mutedIconBg;
  final Color textPrimary;
  final Color textSecondary;

  @override
  DatabaseTheme copyWith({
    Color? appBarBg,
    Color? panelBg,
    Color? contentBg,
    Color? panelBorder,
    Color? surfaceRaised,
    Color? sourceSelectedBg,
    Color? sourceSelectedText,
    Color? mutedIconBg,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return DatabaseTheme(
      appBarBg: appBarBg ?? this.appBarBg,
      panelBg: panelBg ?? this.panelBg,
      contentBg: contentBg ?? this.contentBg,
      panelBorder: panelBorder ?? this.panelBorder,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      sourceSelectedBg: sourceSelectedBg ?? this.sourceSelectedBg,
      sourceSelectedText: sourceSelectedText ?? this.sourceSelectedText,
      mutedIconBg: mutedIconBg ?? this.mutedIconBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  DatabaseTheme lerp(ThemeExtension<DatabaseTheme>? other, double t) {
    if (other is! DatabaseTheme) {
      return this;
    }
    return DatabaseTheme(
      appBarBg: Color.lerp(appBarBg, other.appBarBg, t)!,
      panelBg: Color.lerp(panelBg, other.panelBg, t)!,
      contentBg: Color.lerp(contentBg, other.contentBg, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      sourceSelectedBg:
          Color.lerp(sourceSelectedBg, other.sourceSelectedBg, t)!,
      sourceSelectedText:
          Color.lerp(sourceSelectedText, other.sourceSelectedText, t)!,
      mutedIconBg: Color.lerp(mutedIconBg, other.mutedIconBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }

  static DatabaseTheme fallback(Brightness brightness, ColorScheme scheme) {
    if (brightness == Brightness.dark) {
      return DatabaseTheme(
        appBarBg: const Color(0xFF141518),
        panelBg: const Color(0xFF141518),
        contentBg: const Color(0xFF0E0F11),
        panelBorder: const Color(0xFF222A37),
        surfaceRaised: const Color(0xFF1A1C20),
        sourceSelectedBg: scheme.primary.withValues(alpha: 0.16),
        sourceSelectedText: scheme.primary,
        mutedIconBg: const Color(0xFF1F2530),
        //textPrimary: const Color(0xFFD5D9E0),
        //textSecondary: const Color(0xFFA2ABB9),
        textPrimary: const Color(0xFFFF0000),
        textSecondary: const Color(0xFF00FF00),
      );
    }
    return DatabaseTheme(
      appBarBg: const Color(0xFFF6F8FC),
      panelBg: Colors.white,
      contentBg: const Color(0xFFF7F9FD),
      panelBorder: const Color(0xFFD5DCE7),
      surfaceRaised: const Color(0xFFF0F4FA),
      sourceSelectedBg: scheme.primary.withValues(alpha: 0.12),
      sourceSelectedText: scheme.primary,
      mutedIconBg: const Color(0xFFE9EEF6),
      textPrimary: const Color(0xFF1F2937),
      textSecondary: const Color(0xFF5B6474),
    );
  }
}

extension DatabaseThemeContext on BuildContext {
  DatabaseTheme get databaseTheme {
    final theme = Theme.of(this);
    return theme.extension<DatabaseTheme>() ??
        DatabaseTheme.fallback(theme.brightness, theme.colorScheme);
  }
}
