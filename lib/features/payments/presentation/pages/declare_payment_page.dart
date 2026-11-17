import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/settings/permission_prompts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../../domain/entities/payments.dart';
import '../state/payments_cubits.dart';

/// « Déclarer un paiement » (CU-PAR-11) : montant, date, référence et preuve.
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
  DateTime _paidAt = DateTime.now();
  PaymentProof? _proof;
  bool _prefilled = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  String get _referenceHint => switch (_mode) {
    PaymentMode.mobileMoney => 'Référence de la transaction (ex. MP2611…)',
    PaymentMode.especes => 'Numéro du reçu papier',
    PaymentMode.virement => 'Référence du virement',
  };

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      locale: const Locale('fr'),
      helpText: 'Date du paiement',
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  Future<void> _pickProof() async {
    if (!await ensureFilesPermission(context)) return;
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: PaymentProof.allowedExtensions);
    if (files.isEmpty || !mounted) return;
    final f = files.first;
    final size = f.lengthSync() ?? await f.length() ?? 0;
    if (!mounted) return;
    final proof = PaymentProof(name: f.name, sizeBytes: size, path: f.path);
    if (proof.isTooLarge) {
      context.showMessage('Fichier trop volumineux (5 Mo maximum).', error: true);
      return;
    }
    setState(() => _proof = proof);
  }

  void _submit(FinancialSituation s) {
    FocusScope.of(context).unfocus();
    context.read<DeclarePaymentCubit>().submit((
      childId: context.read<ChildrenCubit>().state.selected?.id ?? '',
      mode: _mode,
      amount: _amount.text,
      paidAt: _paidAt,
      reference: _reference.text,
      proof: _proof,
      balance: s.balance,
    ));
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
                      Text(
                        '${child?.fullName ?? ''} · ${s.year}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      KeyValueRow(
                        'Solde restant',
                        Formatters.fcfa(s.balance),
                        valueStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
                gap20,
                const _Label('Mode de paiement'),
                PillSelector(
                  height: 56,
                  labels: [for (final m in PaymentMode.values) m.label],
                  selected: _mode.index,
                  onChanged: (i) => setState(() => _mode = PaymentMode.values[i]),
                ),
                gap20,
                const _Label('Montant payé (FCFA)'),
                AppTextField(
                  controller: _amount,
                  hint: 'Ex. 45 000',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                gap20,
                const _Label('Date du paiement'),
                _DateField(date: _paidAt, onTap: _pickDate),
                gap20,
                const _Label('Référence'),
                AppTextField(
                  controller: _reference,
                  hint: _referenceHint,
                  prefixIcon: Icons.tag_rounded,
                  textInputAction: TextInputAction.done,
                ),
                gap20,
                const _Label('Preuve de paiement'),
                _ProofField(proof: _proof, onPick: _pickProof, onRemove: () => setState(() => _proof = null)),
                const HelpText('Photo du reçu, capture Mobile Money ou avis de virement · JPG, PNG ou PDF, 5 Mo max.'),
                gap12,
                AppButton(
                  label: 'Envoyer',
                  icon: Icons.send_rounded,
                  loading: submit.isSubmitting,
                  onPressed: () => _submit(s),
                ),
                const HelpText('L’établissement vérifie le paiement puis émet votre reçu.', center: true),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
  );
}

/// Champ « date » au même style que les champs de saisie.
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Date du paiement',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 22, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(Formatters.longDate(date), style: TextStyle(fontSize: 17, color: AppColors.textPrimary)),
              ),
              Icon(Icons.edit_calendar_outlined, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zone de dépôt de la preuve : bouton « Joindre », puis aperçu du fichier choisi.
class _ProofField extends StatelessWidget {
  const _ProofField({required this.proof, required this.onPick, required this.onRemove});

  final PaymentProof? proof;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  static String _size(int bytes) =>
      bytes >= 1024 * 1024 ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo' : '${(bytes / 1024).ceil()} Ko';

  @override
  Widget build(BuildContext context) {
    final p = proof;
    if (p == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppColors.navy.withValues(alpha: 0.5), width: 1.4),
          ),
          child: Column(
            children: [
              Icon(Icons.upload_file_rounded, size: 34, color: AppColors.navy),
              const SizedBox(height: 8),
              Text(
                'Joindre la preuve',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 2),
              Text('Image ou PDF', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final path = p.path;
    final Widget thumb = !p.isPdf && path != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(path), width: 56, height: 56, fit: BoxFit.cover),
          )
        : Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(p.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_outlined, color: AppColors.red),
          );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          thumb,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.isPdf ? 'PDF' : 'Image'} · ${_size(p.sizeBytes)}',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: onPick,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                  child: const Text('Changer de fichier', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Retirer la preuve',
            icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
