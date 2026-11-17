import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'pill_selector.dart';
import 'status_chip.dart';

/// Tuile chiffrée colorée (« 2 Absences », « 1 Retard », « Plus forte 17,5 »).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.tone});

  final String value;
  final String label;

  /// `null` : tuile blanche, texte foncé.
  final StatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final fg = tone?.foreground;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: tone?.background ?? AppColors.surface, borderRadius: cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tone == null) ...[
            Text(label, style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          ] else ...[
            Text(
              value,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: fg),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 17, color: fg)),
          ],
        ],
      ),
    );
  }
}
