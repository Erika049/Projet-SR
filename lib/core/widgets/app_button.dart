import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

enum AppButtonVariant {
  /// Fond marine, texte blanc (« Se connecter »).
  primary,

  /// Fond blanc bordé, texte marine (« Créer un compte parent »).
  secondary,

  /// Fond vert pâle, texte vert (« Faire l'appel »).
  soft,
}

/// Bouton pleine largeur des maquettes. Passé `onPressed: null`, il prend
/// l'apparence grisée (« Bulletin non encore publié »).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  }) : variant = AppButtonVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final (bg, fg, border) = switch ((disabled, variant)) {
      (true, _) => (AppColors.greySoft, AppColors.textSecondary, null),
      (_, AppButtonVariant.primary) => (AppColors.navy, Colors.white, null),
      (_, AppButtonVariant.secondary) => (AppColors.surface, AppColors.navy, AppColors.border),
      (_, AppButtonVariant.soft) => (AppColors.greenSoft, AppColors.green, null),
    };

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg,
          disabledForegroundColor: fg,
          minimumSize: const Size.fromHeight(AppTheme.minTouchTarget),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            side: border == null ? BorderSide.none : BorderSide(color: border, width: 1.2),
          ),
        ),
        child: loading
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Flexible(child: Text(label, textAlign: TextAlign.center)),
                ],
              ),
      ),
    );
  }
}
