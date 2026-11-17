import 'package:flutter/material.dart';

/// Palette issue de la planche « Composants » des maquettes :
/// Marine · Vert · Ambre · Rouge, déclinée en thème clair et thème sombre.
///
/// Les couleurs suivent le thème actif ([useDark]) : ce ne sont donc pas des
/// constantes, et elles ne peuvent pas apparaître dans une expression `const`.
abstract final class AppColors {
  static bool _dark = false;

  static bool get isDark => _dark;

  /// Appelé par l'application quand l'utilisateur change de thème.
  static void useDark(bool dark) => _dark = dark;

  static Color _pick(int light, int dark) => Color(_dark ? dark : light);

  // Couleurs principales
  static Color get navy => _pick(0xFF153F72, 0xFF3D7BC6);
  static Color get green => _pick(0xFF0B7F5E, 0xFF3CC48F);
  static Color get amber => _pick(0xFF7A5300, 0xFFF2B84B);
  static Color get red => _pick(0xFFA83232, 0xFFF07A7A);

  /// Texte/icône posé sur un fond [navy] (boutons principaux, bandeaux).
  static const onNavy = Colors.white;

  // Fonds teintés (badges, bannières, cartes de statut)
  static Color get greenSoft => _pick(0xFFE0F2EC, 0xFF123B30);
  static Color get amberSoft => _pick(0xFFFFF0D4, 0xFF3D2E0E);
  static Color get redSoft => _pick(0xFFFCE4E2, 0xFF3F1D1F);
  static Color get greySoft => _pick(0xFFE5E9F0, 0xFF243243);

  // Surfaces
  static Color get background => _pick(0xFFF0F4F9, 0xFF0E1621);
  static Color get surface => _pick(0xFFFFFFFF, 0xFF172231);
  static Color get border => _pick(0xFFD6DDE6, 0xFF2C3A4D);
  static Color get divider => _pick(0xFFE3E8EF, 0xFF243243);

  /// Fond des bandeaux marine (authentification, page de bienvenue).
  static Color get header => _pick(0xFF153F72, 0xFF10294A);

  // Texte
  static Color get textPrimary => _pick(0xFF142033, 0xFFE6ECF4);
  static Color get textSecondary => _pick(0xFF64748B, 0xFF9AA8BA);
  static Color get textHint => _pick(0xFF7C8594, 0xFF7D8B9E);
}
