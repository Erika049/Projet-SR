import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Groupe de pastilles à choix unique, largeur égale
/// (Français/English, Notes/Présences/Paiements, Tous/Amina/Junior, Lun…Ven).
class PillSelector extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 54,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _Pill(label: labels[i], active: i == selected, height: height, onTap: () => onChanged(i)),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.height, required this.onTap});

  final String label;
  final bool active;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? AppColors.navy : AppColors.surface,
        shape: StadiumBorder(side: active ? BorderSide.none : BorderSide(color: AppColors.border, width: 1.2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Espace vertical standard entre deux blocs.
const gap12 = SizedBox(height: 12);
const gap20 = SizedBox(height: 20);

/// Rayon des cartes, exposé pour les widgets spécifiques aux features.
const cardRadius = BorderRadius.all(Radius.circular(AppTheme.radius + 4));
