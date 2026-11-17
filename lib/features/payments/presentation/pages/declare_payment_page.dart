import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../../domain/entities/payments.dart';
import '../state/payments_cubits.dart';

/// « Déclarer un paiement » (CU-PAR-11).
class DeclarePaymentPage extends StatelessWidget {
  const DeclarePaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final childId = context.read<ChildrenCubit>().state.selected?.id ?? '';
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<DeclarePaymentCubit>()),
        BlocProvider(create: (_) => sl<FinancialSituationCubit>()..load(childId)),
      ],
      child: const _DeclareView(),
    );
  }
}

class _DeclareView extends StatefulWidget {
  const _DeclareView();

  @override
  State<_DeclareView> createState() => _DeclareViewState();
}

class _DeclareViewState extends State<_DeclareView> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  PaymentMode _mode = PaymentMode.mobileMoney;
  bool _prefilled = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = context.read<ChildrenCubit>().state.selected;
    final situation = context.watch<FinancialSituationCubit>().state;
    final submit = context.watch<DeclarePaymentCubit>().state;

    return BlocListener<DeclarePaymentCubit, SubmitState>(
      listener: (context, s) {
        if (s.status == ViewStatus.failure) context.showMessage(s.error!, error: true);
        if (s.isDone) {
          context.showMessage('Déclaration envoyée. L’établissement vérifie puis émet votre reçu.');
          context.pop(true);
        }
      },
      child: AppPage(
        title: 'Déclarer un paiement',
        body: DataStateBuilder(
          state: situation,
          onRetry: context.read<FinancialSituationCubit>().reload,
          builder: (context, s) {
            if (!_prefilled) {
              _prefilled = true;
              _amount.text = Formatters.number(s.nextInstallment?.amount ?? s.balance);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${child?.fullName ?? ''} · ${s.year}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      KeyValueRow(
                        'Solde restant',
                        Formatters.fcfa(s.balance),
                        valueStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
                gap12,
                PillSelector(
                  height: 64,
                  labels: [for (final m in PaymentMode.values) m.label],
                  selected: _mode.index,
                  onChanged: (i) => setState(() => _mode = PaymentMode.values[i]),
                ),
                gap12,
                AppTextField(controller: _amount, hint: 'Montant (FCFA)', keyboardType: TextInputType.number),
                gap12,
                AppTextField(
                  controller: _reference,
                  hint: _mode == PaymentMode.especes ? 'Numéro du reçu papier (facultatif)' : 'Référence de transaction',
                  textInputAction: TextInputAction.done,
                ),
                gap20,
                AppButton(
                  label: 'Envoyer la déclaration',
                  loading: submit.isSubmitting,
                  onPressed: () => context.read<DeclarePaymentCubit>().submit((
                    childId: child?.id ?? '',
                    mode: _mode,
                    amount: _amount.text,
                    reference: _reference.text,
                    balance: s.balance,
                  )),
                ),
                const HelpText('L’établissement vérifie le paiement puis émet votre reçu.'),
              ],
            );
          },
        ),
      ),
    );
  }
}
