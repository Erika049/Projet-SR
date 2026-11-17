import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'pill_selector.dart';

/// Carte blanche arrondie. [accent] dessine la barre verte à gauche
/// (élément sélectionné / mis en avant).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.accent = false,
    this.color = AppColors.surface,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool accent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: accent
              ? const BoxDecoration(border: Border(left: BorderSide(color: AppColors.green, width: 5)))
              : null,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Carte « mise en avant » sur fond marine (moyenne, solde, cours en cours).
class HighlightCard extends StatelessWidget {
  const HighlightCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.navy,
      child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: child),
    );
  }
}

/// Lignes séparées par un trait fin, dans une carte.
class DividedColumn extends StatelessWidget {
  const DividedColumn({super.key, required this.children, this.spacing = 14});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Padding(padding: EdgeInsets.symmetric(vertical: spacing), child: const Divider()),
          children[i],
        ],
      ],
    );
  }
}
