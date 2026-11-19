import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/widgets.dart';
import '../state/children_cubit.dart';
import '../widgets/child_selector.dart';

/// « Fiche de l'enfant » (CU-PAR-04).
class ChildProfilePage extends StatelessWidget {
  const ChildProfilePage({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context) {
    final child = context.watch<ChildrenCubit>().state.byId(childId);
    if (child == null) {
      return const AppPage(
        title: 'Fiche de l’enfant',
        body: MessageView(
          icon: Icons.person_off_outlined,
          title: 'Enfant introuvable',
          message: 'Cet enfant n’est plus rattaché à votre compte.',
        ),
      );
    }
    return AppPage(
      title: 'Fiche de l’enfant',
      onRefresh: context.read<ChildrenCubit>().load,
      children: [
        AppCard(
          child: DividedColumn(
            children: [
              Text(child.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              KeyValueRow('Classe', child.classe),
              KeyValueRow('Établissement', child.etablissement),
              KeyValueRow('Année scolaire', child.anneeScolaire),
              KeyValueRow('Matricule', child.matricule ?? 'Non renseigné'),
            ],
          ),
        ),
        gap12,
        AppCard(
          child: Row(
            children: [
              const Expanded(child: Text('Vos droits', style: TextStyle(fontSize: 17))),
              Wrap(spacing: 8, children: [for (final r in child.rights.labels) StatusChip(r)]),
            ],
          ),
        ),
        gap12,
        AppButton.secondary(label: 'Demander une correction', onPressed: () => showCorrectionDialog(context, child)),
      ],
    );
  }
}
