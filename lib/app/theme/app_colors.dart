import 'package:flutter/material.dart';

/// Palette issue de la planche « Composants » des maquettes :
/// Marine · Vert · Ambre · Rouge.
abstract final class AppColors {
  // Couleurs principales
  static const navy = Color(0xFF153F72);
  static const green = Color(0xFF0B7F5E);
  static const amber = Color(0xFF7A5300);
  static const red = Color(0xFFA83232);

  // Fonds teintés (badges, bannières, cartes de statut)
  static const greenSoft = Color(0xFFE0F2EC);
  static const amberSoft = Color(0xFFFFF0D4);
  static const redSoft = Color(0xFFFCE4E2);
  static const greySoft = Color(0xFFE5E9F0);

  // Surfaces
  static const background = Color(0xFFF0F4F9);
  static const surface = Colors.white;
  static const border = Color(0xFFD6DDE6);
  static const divider = Color(0xFFE3E8EF);

  // Texte
  static const textPrimary = Color(0xFF142033);
  static const textSecondary = Color(0xFF64748B);
  static const textHint = Color(0xFF7C8594);
}
