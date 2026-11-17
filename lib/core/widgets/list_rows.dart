import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Titre de section (« Mes classes » … « 3 classes »).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.onTrailingTap});

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          if (trailing != null)
            InkWell(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: TextStyle(
                  fontSize: 15,
                  color: onTrailingTap != null ? AppColors.navy : AppColors.textSecondary,
                  fontWeight: onTrailingTap != null ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ligne « libellé … valeur » (Fiche de l'enfant, Saisie des notes).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.valueStyle});

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: valueStyle ?? const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// Ligne de menu cliquable avec chevron (« Mes enfants et droits › »).
class NavRow extends StatelessWidget {
  const NavRow(this.label, {super.key, this.value, this.valueColor, this.onTap});

  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: valueColor == null ? 15 : 17,
                    color: valueColor ?? AppColors.textSecondary,
                    fontWeight: valueColor == null ? FontWeight.w400 : FontWeight.w800,
                  ),
                ),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Note d'aide grise sous un bouton.
class HelpText extends StatelessWidget {
  const HelpText(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
      ),
    );
  }
}
