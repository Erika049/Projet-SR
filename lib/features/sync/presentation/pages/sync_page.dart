import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/sync_item.dart';
import '../state/sync_cubit.dart';

/// « Synchronisation » : appels et notes saisis hors connexion.
class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  @override
  void initState() {
    super.initState();
    context.read<SyncCubit>().load();
  }

  Future<void> _resolve(SyncItem item) async {
    final keepLocal = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résoudre le conflit'),
        content: Text('${item.label} sur le serveur et sur ce téléphone. Quelle version garder ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Version du serveur')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ma version')),
        ],
      ),
    );
    if (keepLocal != null && mounted) await context.read<SyncCubit>().resolve(item.id, keepLocal: keepLocal);
  }

  StatusTone _tone(SyncStatus s) => switch (s) {
    SyncStatus.envoye => StatusTone.success,
    SyncStatus.conflit => StatusTone.danger,
    _ => StatusTone.warning,
  };

  Widget _section(String title, List<SyncItem> items, {bool resolvable = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionTitle(title),
      AppCard(
        child: DividedColumn(
          children: [
            for (final i in items)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(i.label, style: const TextStyle(fontSize: 17))),
                      StatusChip(i.status.label, tone: _tone(i.status)),
                    ],
                  ),
                  if (resolvable) ...[gap12, AppButton.secondary(label: 'Résoudre', onPressed: () => _resolve(i))],
                ],
              ),
          ],
        ),
      ),
      gap12,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SyncCubit>().state;
    return AppPage(
      eyebrow: 'SCHOOLCONNECT · ENSEIGNANT',
      title: 'Synchronisation',
      body: DataStateBuilder(
        state: state,
        onRetry: context.read<SyncCubit>().load,
        builder: (context, o) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (o.toSend.isNotEmpty) _section('À envoyer', o.toSend),
            if (o.sent.isNotEmpty) _section('Envoyés', o.sent),
            if (o.conflicts.isNotEmpty) _section('À vérifier', o.conflicts, resolvable: true),
            if (o.items.isEmpty) const HelpText('Tout est à jour.'),
            AppButton(
              label: 'Synchroniser maintenant',
              loading: state.status.isLoading,
              onPressed: () async {
                final msg = await context.read<SyncCubit>().syncNow();
                if (context.mounted) context.showMessage(msg);
              },
            ),
            const HelpText('Les brouillons de notes restent sur ce téléphone tant qu’ils ne sont pas soumis.'),
          ],
        ),
      ),
    );
  }
}
