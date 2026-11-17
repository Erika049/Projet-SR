import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Tonalités de statut des maquettes.
enum StatusTone {
  /// Vert : Justifié, Payé, Actif, Publié.
  success,

  /// Ambre : En attente, Brouillon, Convocation.
  warning,

  /// Rouge : À justifier, Conflit.
  danger,

  /// Gris : Non publié, désactivé.
  neutral;

  Color get foreground => switch (this) {
    success => AppColors.green,
    warning => AppColors.amber,
    danger => AppColors.red,
    neutral => AppColors.textPrimary,
  };

  Color get background => switch (this) {
    success => AppColors.greenSoft,
    warning => AppColors.amberSoft,
    danger => AppColors.redSoft,
    neutral => AppColors.greySoft,
  };
}

/// Petite étiquette colorée (« Justifié », « En attente », « À justifier »).
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = StatusTone.success, this.onTap});

  final String label;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label,
        style: TextStyle(color: tone.foreground, fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
    if (onTap == null) return chip;
    return InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap, child: chip);
  }
}
