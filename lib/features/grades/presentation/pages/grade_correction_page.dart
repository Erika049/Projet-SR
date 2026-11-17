import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/grades.dart';
import '../state/grades_cubits.dart';

/// « Corriger une note » (CU-ENS-05) : modification tracée.
class GradeCorrectionPage extends StatelessWidget {
  const GradeCorrectionPage({super.key, required this.sheet, required this.grade});

  final GradeSheet sheet;
  final StudentGrade grade;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => sl<CorrectionCubit>(),
        child: _CorrectionView(sheet: sheet, grade: grade),
      );
}

class _CorrectionView extends StatefulWidget {
  const _CorrectionView({required this.sheet, required this.grade});
  final GradeSheet sheet;
  final StudentGrade grade;

  @override
  State<_CorrectionView> createState() => _CorrectionViewState();
}

class _CorrectionViewState extends State<_CorrectionView> {
  final _value = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final grade = widget.grade;
    final state = context.watch<CorrectionCubit>().state;
    final current = grade.absent ? 'Abs.' : (grade.value == null ? '—' : Formatters.grade(grade.value!));

    return BlocListener<CorrectionCubit, SubmitState>(
      listener: (context, s) {
        if (s.status == ViewStatus.failure) context.showMessage(s.error!, error: true);
        if (s.isDone) {
          context.showMessage('Correction enregistrée.');
          context.pop(true);
        }
      },
      child: AppPage(
        eyebrow: 'SCHOOLCONNECT · ENSEIGNANT',
        title: 'Corriger une note',
        children: [
          AppCard(
            child: DividedColumn(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${grade.studentName} · ${sheet.className}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      '${sheet.subject} · ${sheet.period.label} · coef. ${Formatters.grade(sheet.coefficient, decimals: 0)}',
                      style: context.text.bodySmall?.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                KeyValueRow('Note actuelle', current),
              ],
            ),
          ),
          gap12,
          AppTextField(
            controller: _value,
            hint: 'Nouvelle note',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          gap12,
          AppTextField(controller: _reason, hint: 'Motif (ex. erreur de report)', textInputAction: TextInputAction.done),
          HelpText(
            sheet.openUntil == null
                ? 'La modification est enregistrée avec son auteur et sa date.'
                : 'Période ouverte jusqu’au ${DateFormat('d MMMM', 'fr_FR').format(sheet.openUntil!)}. '
                    'La modification est enregistrée avec son auteur et sa date.',
          ),
          AppButton(
            label: 'Enregistrer la correction',
            loading: state.isSubmitting,
            onPressed: () => context.read<CorrectionCubit>().submit((
              sheet: sheet,
              studentId: grade.studentId,
              input: _value.text,
              reason: _reason.text,
            )),
          ),
        ],
      ),
    );
  }
}
