import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/grades.dart';
import '../state/grades_cubits.dart';

/// Onglet « Notes » du suivi de l'enfant (CU-PAR-07).
/// Le sélecteur d'enfant est affiché par la page parente.
class ChildGradesView extends StatelessWidget {
  const ChildGradesView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChildGradesCubit>().state;
    final cubit = context.read<ChildGradesCubit>();
    final period = state.period;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillSelector(
          labels: const ['Séquences', 'Trimestres'],
          selected: state.kind == PeriodKind.sequence ? 0 : 1,
          onChanged: (i) => cubit.selectKind(i == 0 ? PeriodKind.sequence : PeriodKind.trimestre),
        ),
        gap12,
        if (period != null)
          SelectField<Period>(
            value: period,
            options: state.visiblePeriods,
            labelOf: (p) => p.fullLabel,
            sheetTitle: 'Choisir une période',
            onChanged: (p) => cubit.selectPeriod(p.id),
          ),
        gap12,
        if (state.report.status == ViewStatus.loading)
          const Padding(padding: EdgeInsets.all(40), child: LoadingView())
        else if (state.report.status == ViewStatus.failure)
          ErrorView(failure: state.report.failure!, onRetry: () => cubit.selectPeriod(state.periodId!))
        else if (state.report.data != null)
          _Report(report: state.report.data!),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report});
  final GradesReport report;

  @override
  Widget build(BuildContext context) {
    final average = report.average;
    if (report.subjects.isEmpty) {
      return const AppCard(
        child: Text(
          'Les notes de cette période ne sont pas encore publiées.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighlightCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Moyenne pondérée', style: TextStyle(fontSize: 16)),
                    Text(
                      average == null ? '—' : '${Formatters.grade(average)} / 20',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (report.rank != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Rang', style: TextStyle(fontSize: 16)),
                    Text(
                      '${Formatters.rank(report.rank!)} / ${report.classSize}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
            ],
          ),
        ),
        gap12,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Row('MATIÈRE', 'COEF.', 'NOTE / 20', header: true),
              for (final s in report.subjects) ...[
                const Divider(height: 24),
                _Row(
                  s.subject,
                  Formatters.grade(s.coefficient, decimals: 0),
                  s.grade == null ? '—' : Formatters.grade(s.grade!),
                ),
              ],
              const Divider(height: 24),
              const Text(
                'Moyenne = Σ(note × coef.) / Σ coef.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        gap12,
        AppButton(
          label: report.reportCardPublished ? 'Voir les bulletins' : 'Bulletin non encore publié',
          onPressed: report.reportCardPublished ? () => context.push(Routes.parentReportCards) : null,
        ),
        if (!report.reportCardPublished) ...[
          const HelpText('Disponible après validation par la direction.', center: true),
          TextButton(
            onPressed: () => context.push(Routes.parentReportCards),
            child: const Text('Voir tous les bulletins'),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.subject, this.coef, this.grade, {this.header = false});

  final String subject;
  final String coef;
  final String grade;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final base = header
        ? const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textSecondary)
        : const TextStyle(fontSize: 17);
    return Row(
      children: [
        Expanded(flex: 5, child: Text(subject, style: base)),
        Expanded(flex: 2, child: Text(coef, textAlign: TextAlign.center, style: base)),
        Expanded(
          flex: 3,
          child: Text(
            grade,
            textAlign: TextAlign.end,
            style: header ? base : base.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
        ),
      ],
    );
  }
}
