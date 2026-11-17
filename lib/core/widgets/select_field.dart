import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'app_card.dart';

/// Sélecteur affiché comme une carte blanche avec chevron
/// (« Amina Etame · 3e A ⌄ », « Séquence 1 · 2026–2027 ⌄ »).
/// Ouvre une feuille de choix en bas de l'écran.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.sheetTitle,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? sheetTitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      onTap: options.length < 2 ? null : () => _open(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              labelOf(value),
              style: const TextStyle(fontSize: 17, color: AppColors.textSecondary),
            ),
          ),
          if (options.length > 1) const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            if (sheetTitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(sheetTitle!, style: Theme.of(context).textTheme.titleLarge),
              ),
            for (final o in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(labelOf(o)),
                trailing: o == value ? const Icon(Icons.check_rounded, color: AppColors.navy) : null,
                onTap: () => Navigator.pop(context, o),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != value) onChanged(picked);
  }
}
