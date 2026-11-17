import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/child.dart';
import '../state/children_cubit.dart';

/// Sélecteur d'enfant partagé par les écrans de suivi
/// (« Amina Etame · 3e A ⌄ »). [suffix] remplace la classe dans le libellé
/// (ex. « Novembre 2026 », « Année 2026–2027 »).
class ChildSelector extends StatelessWidget {
  const ChildSelector({super.key, this.suffix});

  final String Function(Child child)? suffix;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChildrenCubit>().state;
    final selected = state.selected;
    if (selected == null) return const SizedBox.shrink();
    return SelectField<Child>(
      value: selected,
      options: state.children,
      sheetTitle: 'Choisir un enfant',
      labelOf: (c) => suffix == null ? c.label : '${c.fullName} · ${suffix!(c)}',
      onChanged: (c) => context.read<ChildrenCubit>().select(c.id),
    );
  }
}

/// Boîte de dialogue « Demander une correction » (CU-PAR-17).
Future<void> showCorrectionDialog(BuildContext context, Child child) async {
  final controller = TextEditingController();
  final cubit = context.read<ChildrenCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final message = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Demander une correction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(child.label),
          const SizedBox(height: 12),
          AppTextField(controller: controller, hint: 'Information à corriger', maxLines: 3),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Envoyer')),
      ],
    ),
  );
  controller.dispose();
  if (message == null) return;
  final error = await cubit.requestCorrection(child.id, message);
  messenger.showSnackBar(SnackBar(content: Text(error ?? 'Demande envoyée au secrétariat.')));
}
