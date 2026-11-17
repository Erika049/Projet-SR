import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Échelle typographique des maquettes : Titres 24 · Corps 14 · Actions 15.
/// Cibles tactiles ≥ 44 px.
abstract final class AppTheme {
  static const double radius = 14;
  static const double minTouchTarget = 48;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 16, 20, 24);

  /// Thème clair ou sombre selon [dark]. Bascule aussi la palette [AppColors].
  static ThemeData build({required bool dark}) {
    AppColors.useDark(dark);
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: dark ? Brightness.dark : Brightness.light,
        seedColor: AppColors.navy,
        onPrimary: AppColors.onNavy,
        onSurface: AppColors.textPrimary,
        primary: AppColors.navy,
        secondary: AppColors.green,
        error: AppColors.red,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
    );

    final text = base.textTheme.apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);

    return base.copyWith(
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
        titleLarge: text.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 15),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: text.bodySmall?.copyWith(fontSize: 13, color: AppColors.textSecondary),
        labelLarge: text.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.navy, width: 1.6),
        errorBorder: _inputBorder(AppColors.red),
        focusedErrorBorder: _inputBorder(AppColors.red, width: 1.6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) =>
              IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.navy : AppColors.textSecondary),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.surface),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.2}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color, width: width),
  );
}
