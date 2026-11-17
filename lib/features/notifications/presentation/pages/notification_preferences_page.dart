import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../../../children/presentation/widgets/child_selector.dart';
import '../../domain/entities/notifications.dart';
import '../state/notifications_cubits.dart';

/// « Préférences d'alertes », réglables pour chaque enfant (CU-PAR-16).
class NotificationPreferencesPage extends StatelessWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final childId = context.read<ChildrenCubit>().state.selected?.id ?? '';
    return BlocProvider(
      create: (_) => sl<PreferencesCubit>()..load(childId),
      child: BlocListener<ChildrenCubit, ChildrenState>(
        listenWhen: (a, b) => a.selectedId != b.selectedId,
        listener: (context, s) => context.read<PreferencesCubit>().load(s.selected!.id),
        child: const _PreferencesView(),
      ),
    );
  }
}

class _PreferencesView extends StatelessWidget {
  const _PreferencesView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PreferencesCubit>().state;
    final cubit = context.read<PreferencesCubit>();

    Future<void> run(Future<String?> action) async {
      final error = await action;
      if (error != null && context.mounted) context.showMessage(error, error: true);
    }

    return AppPage(
      title: 'Préférences d’alertes',
      children: [
        ChildSelector(suffix: (c) => c.classe),
        gap12,
        DataStateBuilder(
          state: state,
          onRetry: () => cubit.load(context.read<ChildrenCubit>().state.selected!.id),
          builder: (context, p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Canaux'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in NotificationChannel.values)
                    StatusChip(
                      '${c.label} · ${p.channels.contains(c) ? 'activé' : 'désactivé'}',
                      tone: p.channels.contains(c) ? StatusTone.success : StatusTone.neutral,
                      onTap: () => run(cubit.toggleChannel(c)),
                    ),
                ],
              ),
              gap20,
              AppCard(
                child: DividedColumn(
                  children: [
                    for (final type in NotificationType.values)
                      Row(
                        children: [
                          Expanded(child: Text(type.label, style: const TextStyle(fontSize: 17))),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final c in NotificationChannel.values)
                                if (p.channels.contains(c))
                                  StatusChip(
                                    c.label,
                                    tone: (p.byType[type] ?? const {}).contains(c)
                                        ? StatusTone.success
                                        : StatusTone.neutral,
                                    onTap: () => run(cubit.toggle(type, c)),
                                  ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const HelpText('Touchez un canal pour l’activer ou le désactiver.'),
            ],
          ),
        ),
      ],
    );
  }
}
