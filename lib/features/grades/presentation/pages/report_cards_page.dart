import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../../../children/presentation/widgets/child_selector.dart';
import '../state/grades_cubits.dart';

/// « Bulletins » (CU-PAR-08).
class ReportCardsPage extends StatelessWidget {
  const ReportCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final childId = context.read<ChildrenCubit>().state.selected?.id;
    return BlocProvider(
      create: (_) => sl<ReportCardsCubit>()..load(childId ?? ''),
      child: BlocListener<ChildrenCubit, ChildrenState>(
        listenWhen: (a, b) => a.selectedId != b.selectedId,
        listener: (context, s) => context.read<ReportCardsCubit>().load(s.selected!.id),
        child: const _ReportCardsView(),
      ),
    );
  }
}

class _ReportCardsView extends StatelessWidget {
  const _ReportCardsView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReportCardsCubit>().state;
    return AppPage(
      title: 'Bulletins',
      children: [
        const ChildSelector(),
        gap12,
        DataStateBuilder(
          state: state,
          onRetry: () => context.read<ReportCardsCubit>().load(context.read<ChildrenCubit>().state.selected!.id),
          builder: (context, cards) => Column(
            children: [
              for (final card in cards) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              card.periodLabel,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ),
                          card.published
                              ? const StatusChip('Publié')
                              : const StatusChip('Non publié', tone: StatusTone.neutral),
                        ],
                      ),
                      if (card.published) ...[
                        gap12,
                        AppButton(
                          label: 'Télécharger le PDF',
                          onPressed: () async {
                            final msg = await context.read<ReportCardsCubit>().download(card);
                            if (context.mounted) context.showMessage(msg);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                gap12,
              ],
              const HelpText('Vous êtes notifié dès la publication par l’établissement.'),
            ],
          ),
        ),
      ],
    );
  }
}
