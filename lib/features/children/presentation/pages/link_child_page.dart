import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/child.dart';
import '../state/children_cubit.dart';
import '../widgets/child_selector.dart';

/// « Lier un enfant » (CU-PAR-02).
class LinkChildPage extends StatefulWidget {
  const LinkChildPage({super.key});

  @override
  State<LinkChildPage> createState() => _LinkChildPageState();
}

class _LinkChildPageState extends State<LinkChildPage> {
  final _code = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    setState(() => _sending = true);
    final error = await context.read<ChildrenCubit>().link(_code.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) return context.showMessage(error, error: true);
    _code.clear();
    context.showMessage('Demande envoyée. Le secrétariat va la valider.');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChildrenCubit>().state;
    return AppPage(
      title: 'Lier un enfant',
      children: [
        Text(
          'Saisissez le code de liaison remis par le secrétariat de l’école (8 lettres ou chiffres).',
          style: context.text.bodySmall?.copyWith(fontSize: 15),
        ),
        gap12,
        AppTextField(controller: _code, hint: 'XXXX-XXXX', textInputAction: TextInputAction.done),
        gap12,
        AppButton(label: 'Lier cet enfant', loading: _sending, onPressed: _link),
        if (state.requests.isNotEmpty) ...[
          gap20,
          const SectionTitle('Demandes en cours'),
          for (final r in state.requests) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('${r.childName} · ${r.classe}', style: const TextStyle(fontSize: 17))),
                      const StatusChip('En attente de validation', tone: StatusTone.warning),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Le secrétariat valide la demande.', style: context.text.bodySmall?.copyWith(fontSize: 15)),
                ],
              ),
            ),
            gap12,
          ],
        ],
        if (state.children.isNotEmpty) ...[
          gap12,
          const SectionTitle('Enfants rattachés'),
          for (final c in state.children) ...[_LinkedChildCard(child: c), gap12],
        ],
      ],
    );
  }
}

class _LinkedChildCard extends StatelessWidget {
  const _LinkedChildCard({required this.child});
  final Child child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(child.label, style: const TextStyle(fontSize: 17))),
              const StatusChip('Actif'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Droits : ${child.rights.labels.map((e) => e.toLowerCase()).join(' · ')}',
            style: context.text.bodySmall?.copyWith(fontSize: 15),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                onTap: () => confirmUnlink(context, child),
                child: Text('Se dissocier', style: context.text.bodySmall?.copyWith(fontSize: 15)),
              ),
              Text(' · ', style: context.text.bodySmall),
              InkWell(
                onTap: () => showCorrectionDialog(context, child),
                child: Text('Demander une correction', style: context.text.bodySmall?.copyWith(fontSize: 15)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Confirmation avant de se dissocier d'un enfant.
Future<void> confirmUnlink(BuildContext context, Child child) async {
  final cubit = context.read<ChildrenCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Se dissocier ?'),
      content: Text(
        'Vous ne verrez plus les informations de ${child.fullName}. '
        'Une nouvelle liaison devra être validée par l’école.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Se dissocier')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final error = await cubit.unlink(child.id);
  if (context.mounted) context.showMessage(error ?? '${child.fullName} a été dissocié(e).', error: error != null);
}
