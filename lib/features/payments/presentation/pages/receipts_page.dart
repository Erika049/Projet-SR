import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../../domain/entities/payments.dart';
import '../state/payments_cubits.dart';

/// « Reçus et historique » (CU-PAR-12).
class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final childId = context.read<ChildrenCubit>().state.selected?.id ?? '';
    return BlocProvider(
      create: (_) => sl<PaymentHistoryCubit>()..load(childId),
      child: Builder(
        builder: (context) {
          final state = context.watch<PaymentHistoryCubit>().state;
          return AppPage(
            title: 'Reçus et historique',
            body: DataStateBuilder(
              state: state,
              onRetry: () => context.read<PaymentHistoryCubit>().load(childId),
              builder: (context, list) => list.isEmpty
                  ? const MessageView(
                      icon: Icons.receipt_long_outlined,
                      title: 'Aucun paiement',
                      message: 'Vos reçus apparaîtront ici après chaque paiement validé.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => gap12,
                      itemBuilder: (context, i) => _PaymentCard(payment: list[i]),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final title = p.hasReceipt ? 'Reçu du ${Formatters.shortDate(p.date)}' : 'Déclaration du ${Formatters.shortDate(p.date)}';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              StatusChip(
                p.status.label,
                tone: switch (p.status) {
                  PaymentStatus.confirme => StatusTone.success,
                  PaymentStatus.enAttente => StatusTone.warning,
                  PaymentStatus.rejete => StatusTone.danger,
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${Formatters.fcfa(p.amount)} · ${p.mode.label}', style: context.text.bodySmall?.copyWith(fontSize: 15)),
          if (p.hasReceipt) ...[
            gap12,
            AppButton.secondary(
              label: 'Télécharger le PDF',
              onPressed: () async {
                final msg = await context.read<PaymentHistoryCubit>().download(p);
                if (context.mounted) context.showMessage(msg);
              },
            ),
          ],
        ],
      ),
    );
  }
}
