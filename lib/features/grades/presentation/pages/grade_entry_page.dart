import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/grades.dart';
import '../state/grades_cubits.dart';

/// « Saisie des notes » (CU-ENS-04).
class GradeEntryPage extends StatelessWidget {
  const GradeEntryPage({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) => BlocProvider(
        key: ValueKey(classId),
        create: (_) => sl<GradeSheetCubit>()..load(classId),
        child: _GradeEntryView(classId: classId),
      );
}

class _GradeEntryView extends StatelessWidget {
  const _GradeEntryView({required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GradeSheetCubit>().state;
    final cubit = context.read<GradeSheetCubit>();

    return BlocListener<GradeSheetCubit, GradeSheetState>(
      listenWhen: (a, b) => b.message != null && a.message != b.message,
      listener: (context, s) => context.showMessage(s.message!),
      child: AppPage(
        eyebrow: 'SCHOOLCONNECT · ENSEIGNANT',
        title: 'Saisie des notes',
        body: DataStateBuilder(
          state: state.sheet,
          onRetry: () => cubit.load(classId),
          builder: (context, sheet) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              FutureBuilder<bool>(
                future: sl<NetworkInfo>().isConnected,
                builder: (context, snap) => snap.data == false
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: InfoBanner.offline('Hors connexion · brouillon local'),
                      )
                    : const SizedBox.shrink(),
              ),
              AppCard(
                child: Column(
                  children: [
                    KeyValueRow('Classe', sheet.className),
                    const SizedBox(height: 8),
                    KeyValueRow('Matière', sheet.subject),
                    const SizedBox(height: 8),
                    KeyValueRow('Période', sheet.period.label),
                    const SizedBox(height: 8),
                    KeyValueRow('Évaluation', sheet.evaluationLabel),
                  ],
                ),
              ),
              gap12,
              Wrap(
                spacing: 8,
                children: [
                  for (final s in GradeSheetStatus.values)
                    StatusChip(s.label, tone: s == sheet.status ? StatusTone.warning : StatusTone.neutral),
                ],
              ),
              gap12,
              SectionTitle(
                'Notes sur ${Formatters.grade(sheet.scale, decimals: 0)}',
                trailing: 'Coef. ${Formatters.grade(sheet.coefficient, decimals: 0)}',
              ),
              AppCard(
                child: DividedColumn(
                  children: [
                    for (final g in sheet.grades)
                      _GradeRow(
                        grade: g,
                        input: state.inputs[g.studentId] ?? '',
                        error: state.errorFor(g.studentId),
                        editable: sheet.editable,
                        onChanged: (v) => cubit.setInput(g.studentId, v),
                        onCorrect: sheet.editable
                            ? null
                            : () => context.push(Routes.teacherGradeCorrection, extra: (sheet: sheet, grade: g)),
                      ),
                  ],
                ),
              ),
              HelpText(
                '${state.validCount} notes valides · ${state.errorCount} erreur${state.errorCount > 1 ? 's' : ''}'
                ' · ${state.remaining} restantes',
              ),
              if (sheet.editable) ...[
                AppButton.secondary(
                  label: 'Enregistrer le brouillon',
                  loading: state.saving,
                  onPressed: state.errorCount == 0 ? () => cubit.save(submit: false) : null,
                ),
                gap12,
                AppButton(
                  label: state.errorCount > 0 ? 'Soumettre (corrigez l’erreur)' : 'Soumettre',
                  onPressed: state.canSubmit && !state.saving ? () => cubit.save(submit: true) : null,
                ),
              ] else
                const HelpText('Notes soumises. Touchez une note pour la corriger pendant la période ouverte.'),
              gap20,
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Appréciations',
                      onPressed: () => context.push(Routes.teacherAppreciations(classId)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Statistiques',
                      onPressed: () => context.push(Routes.teacherStats(classId)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({
    required this.grade,
    required this.input,
    required this.error,
    required this.editable,
    required this.onChanged,
    this.onCorrect,
  });

  final StudentGrade grade;
  final String input;
  final String? error;
  final bool editable;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCorrect;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCorrect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(child: Text(grade.studentName, style: const TextStyle(fontSize: 17))),
              SizedBox(
                width: 96,
                child: editable
                    ? TextFormField(
                        initialValue: input,
                        textAlign: TextAlign.end,
                        keyboardType: TextInputType.text,
                        onChanged: onChanged,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: '—',
                          errorText: error == null ? null : '',
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
                        ),
                      )
                    : Text(
                        input.isEmpty ? '—' : input,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            StatusChip(error!, tone: StatusTone.danger),
          ],
        ],
      ),
    );
  }
}
