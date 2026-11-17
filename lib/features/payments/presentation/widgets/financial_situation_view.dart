import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../state/payments_cubits.dart';

/// Onglet « Paiements » du suivi de l'enfant (CU-PAR-10).
class FinancialSituationView extends StatelessWidget {
  const FinancialSituationView({super.key, required this.canPay});

  final bool canPay;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinancialSituationCubit>().state;
    return DataStateBuilder(
      state: state,
      onRetry: context.read<FinancialSituationCubit>().reload,
      builder: (context, s) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighlightCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Solde restant', style: TextStyle(fontSize: 16)),
                Text(
                  Formatters.fcfa(s.balance),
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Frais : ${Formatters.fcfa(s.totalDue)} • Payé : ${Formatters.fcfa(s.totalPaid)}',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          gap12,
          AppCard(
            child: DividedColumn(
              children: [
                for (final i in s.installments)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(i.label, style: const TextStyle(fontSize: 17))),
                          Text(
                            i.paid ? '${Formatters.fcfa(i.amount)} · Payé' : Formatters.fcfa(i.amount),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: i.paid ? AppColors.green : AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                      if (!i.paid) ...[
                        const SizedBox(height: 4),
                        Text(
                          'À régler avant le ${DateFormat('d MMMM', 'fr_FR').format(i.dueDate)}',
                          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          gap12,
          if (s.balance > 0 && canPay) ...[
            AppButton(
              label: 'Déclarer un paiement',
              onPressed: () async {
                final sent = await context.push<bool>(Routes.parentDeclarePayment);
                if (sent == true && context.mounted) await context.read<FinancialSituationCubit>().reload();
              },
            ),
            const HelpText('Indiquez le moyen et la référence de transaction. L’économat valide et émet le reçu.'),
            const Row(
              children: [
                Expanded(child: _SoonTile('MTN MoMo · bientôt')),
                SizedBox(width: 12),
                Expanded(child: _SoonTile('Orange Money · bientôt')),
              ],
            ),
            gap12,
          ],
          AppCard(
            onTap: () => context.push(Routes.parentReceipts),
            child: Row(
              children: [
                Expanded(
                  child: s.lastReceipt == null
                      ? const Text('Aucun reçu pour le moment', style: TextStyle(fontSize: 17))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reçu du ${Formatters.shortDate(s.lastReceipt!.date)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${Formatters.fcfa(s.lastReceipt!.amount)} · PDF',
                              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                ),
                Text('Historique ›', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paiement en ligne prévu dans une version ultérieure (cahier des charges).
class _SoonTile extends StatelessWidget {
  const _SoonTile(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.greySoft, borderRadius: cardRadius),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }
}
