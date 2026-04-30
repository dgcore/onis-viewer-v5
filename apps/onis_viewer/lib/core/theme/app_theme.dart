import 'package:flutter/material.dart';

@immutable
class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({
    required this.appBarBg,
    required this.statusBarBg,
    required this.panelBg,
    required this.contentBg,
    required this.panelBorder,
    required this.surfaceRaised,
    required this.selectionBg,
    required this.selectionText,
    required this.mutedIconBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.listHeaderBg,
    required this.listHeaderBorder,
    required this.listHeaderText,
    required this.listHeaderMutedText,
    required this.listFilterBg,
    required this.listFilterFieldBg,
    required this.listFilterFieldBorder,
    required this.listFilterHintText,
    required this.listRowBg,
    required this.listRowBorder,
    required this.listCellSeparator,
    required this.listRowSelectedBg,
    required this.listRowText,
    required this.listRowSelectedText,
  });

  final Color appBarBg;
  final Color statusBarBg;
  final Color panelBg;
  final Color contentBg;
  final Color panelBorder;
  final Color surfaceRaised;
  final Color selectionBg;
  final Color selectionText;
  final Color mutedIconBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color listHeaderBg;
  final Color listHeaderBorder;
  final Color listHeaderText;
  final Color listHeaderMutedText;
  final Color listFilterBg;
  final Color listFilterFieldBg;
  final Color listFilterFieldBorder;
  final Color listFilterHintText;
  final Color listRowBg;
  final Color listRowBorder;
  final Color listCellSeparator;
  final Color listRowSelectedBg;
  final Color listRowText;
  final Color listRowSelectedText;

  @override
  AppTheme copyWith({
    Color? appBarBg,
    Color? statusBarBg,
    Color? panelBg,
    Color? contentBg,
    Color? panelBorder,
    Color? surfaceRaised,
    Color? selectionBg,
    Color? selectionText,
    Color? mutedIconBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? listHeaderBg,
    Color? listHeaderBorder,
    Color? listHeaderText,
    Color? listHeaderMutedText,
    Color? listFilterBg,
    Color? listFilterFieldBg,
    Color? listFilterFieldBorder,
    Color? listFilterHintText,
    Color? listRowBg,
    Color? listRowBorder,
    Color? listCellSeparator,
    Color? listRowSelectedBg,
    Color? listRowText,
    Color? listRowSelectedText,
  }) {
    return AppTheme(
      appBarBg: appBarBg ?? this.appBarBg,
      statusBarBg: statusBarBg ?? this.statusBarBg,
      panelBg: panelBg ?? this.panelBg,
      contentBg: contentBg ?? this.contentBg,
      panelBorder: panelBorder ?? this.panelBorder,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      selectionBg: selectionBg ?? this.selectionBg,
      selectionText: selectionText ?? this.selectionText,
      mutedIconBg: mutedIconBg ?? this.mutedIconBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      listHeaderBg: listHeaderBg ?? this.listHeaderBg,
      listHeaderBorder: listHeaderBorder ?? this.listHeaderBorder,
      listHeaderText: listHeaderText ?? this.listHeaderText,
      listHeaderMutedText: listHeaderMutedText ?? this.listHeaderMutedText,
      listFilterBg: listFilterBg ?? this.listFilterBg,
      listFilterFieldBg: listFilterFieldBg ?? this.listFilterFieldBg,
      listFilterFieldBorder:
          listFilterFieldBorder ?? this.listFilterFieldBorder,
      listFilterHintText: listFilterHintText ?? this.listFilterHintText,
      listRowBg: listRowBg ?? this.listRowBg,
      listRowBorder: listRowBorder ?? this.listRowBorder,
      listCellSeparator: listCellSeparator ?? this.listCellSeparator,
      listRowSelectedBg: listRowSelectedBg ?? this.listRowSelectedBg,
      listRowText: listRowText ?? this.listRowText,
      listRowSelectedText: listRowSelectedText ?? this.listRowSelectedText,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
      appBarBg: Color.lerp(appBarBg, other.appBarBg, t)!,
      statusBarBg: Color.lerp(statusBarBg, other.statusBarBg, t)!,
      panelBg: Color.lerp(panelBg, other.panelBg, t)!,
      contentBg: Color.lerp(contentBg, other.contentBg, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      selectionBg: Color.lerp(selectionBg, other.selectionBg, t)!,
      selectionText: Color.lerp(selectionText, other.selectionText, t)!,
      mutedIconBg: Color.lerp(mutedIconBg, other.mutedIconBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      listHeaderBg: Color.lerp(listHeaderBg, other.listHeaderBg, t)!,
      listHeaderBorder:
          Color.lerp(listHeaderBorder, other.listHeaderBorder, t)!,
      listHeaderText: Color.lerp(listHeaderText, other.listHeaderText, t)!,
      listHeaderMutedText:
          Color.lerp(listHeaderMutedText, other.listHeaderMutedText, t)!,
      listFilterBg: Color.lerp(listFilterBg, other.listFilterBg, t)!,
      listFilterFieldBg:
          Color.lerp(listFilterFieldBg, other.listFilterFieldBg, t)!,
      listFilterFieldBorder:
          Color.lerp(listFilterFieldBorder, other.listFilterFieldBorder, t)!,
      listFilterHintText:
          Color.lerp(listFilterHintText, other.listFilterHintText, t)!,
      listRowBg: Color.lerp(listRowBg, other.listRowBg, t)!,
      listRowBorder: Color.lerp(listRowBorder, other.listRowBorder, t)!,
      listCellSeparator:
          Color.lerp(listCellSeparator, other.listCellSeparator, t)!,
      listRowSelectedBg:
          Color.lerp(listRowSelectedBg, other.listRowSelectedBg, t)!,
      listRowText: Color.lerp(listRowText, other.listRowText, t)!,
      listRowSelectedText:
          Color.lerp(listRowSelectedText, other.listRowSelectedText, t)!,
    );
  }

  static AppTheme fallback(Brightness brightness, ColorScheme scheme) {
    if (brightness == Brightness.dark) {
      return AppTheme(
        appBarBg: const Color(0xFF141518),
        statusBarBg: const Color(0xFF141518),
        panelBg: const Color(0xFF141518),
        contentBg: const Color(0xFF0E0F11),
        panelBorder: const Color(0xFF222A37),
        surfaceRaised: const Color(0xFF1A1C20),
        selectionBg: scheme.primary.withValues(alpha: 0.16),
        selectionText: scheme.primary,
        mutedIconBg: const Color(0xFF1F2530),
        textPrimary: const Color(0xFF9F9F9F),
        textSecondary: const Color(0xFF9F9F9F),
        listHeaderBg: const Color(0xFF141518),
        listHeaderBorder: const Color(0xFF1C2230),
        listHeaderText: const Color(0xFF676767),
        listHeaderMutedText: const Color(0xFF7E8898),
        listFilterBg: const Color(0xFF0D1118),
        // Keep search boxes on the previous medium dark tone.
        listFilterFieldBg: const Color(0xFF4A4A4A),
        listFilterFieldBorder: const Color(0xFF3A414C),
        listFilterHintText: const Color(0xFF7A8391),
        listRowBg: const Color(0xFF0E0F11),
        listRowBorder: const Color(0xFF141A25),
        listCellSeparator: const Color(0xFF1A2230),
        listRowSelectedBg: const Color(0xFF132940),
        listRowText: const Color(0xFFC1C7D3),
        listRowSelectedText: const Color(0xFFE1E7F2),
      );
    }
    return AppTheme(
      appBarBg: const Color(0xFFF6F8FC),
      statusBarBg: const Color(0xFFE9EEF6),
      panelBg: Colors.white,
      contentBg: const Color(0xFFF7F9FD),
      panelBorder: const Color(0xFFD5DCE7),
      surfaceRaised: const Color(0xFFF0F4FA),
      selectionBg: scheme.primary.withValues(alpha: 0.12),
      selectionText: scheme.primary,
      mutedIconBg: const Color(0xFFE9EEF6),
      textPrimary: const Color(0xFF1F2937),
      textSecondary: const Color(0xFF5B6474),
      listHeaderBg: const Color(0xFFF5F7FB),
      listHeaderBorder: const Color(0xFFD8DFEB),
      listHeaderText: const Color(0xFF2C3645),
      listHeaderMutedText: const Color(0xFF6C7788),
      listFilterBg: const Color(0xFFF8FAFD),
      listFilterFieldBg: Colors.white,
      listFilterFieldBorder: const Color(0xFFD5DCE7),
      listFilterHintText: const Color(0xFF7A8698),
      listRowBg: Colors.white,
      listRowBorder: const Color(0xFFE4E9F2),
      listCellSeparator: const Color(0xFFDCE3EF),
      listRowSelectedBg: const Color(0xFFE9F3FF),
      listRowText: const Color(0xFF2B3342),
      listRowSelectedText: const Color(0xFF1D4F87),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppTheme get appTheme {
    final theme = Theme.of(this);
    return theme.extension<AppTheme>() ??
        AppTheme.fallback(theme.brightness, theme.colorScheme);
  }
}
