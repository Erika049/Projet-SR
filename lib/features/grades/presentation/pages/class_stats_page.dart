import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../state/grades_cubits.dart';

/// « Statistiques · 3e A » (CU-ENS-07).
class ClassStatsPage extends StatelessWidget {
  const ClassStatsPage({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ClassStatsCubit>()..load(classId),
      child: Builder(
        builder: (context) {
          final state = context.watch<ClassStatsCubit>().state;
          return AppPage(
            eyebrow: 'SCHOOLCONNECT · ENSEIGNANT',
            title: state.data == null ? 'Statistiques' : 'Statistiques · ${state.data!.className}',
            body: DataStateBuilder(
              state: state,
              onRetry: () => context.read<ClassStatsCubit>().load(classId),
              builder: (context, s) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  HighlightCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Moyenne de la classe', style: TextStyle(fontSize: 16)),
                              Text(
                                '${Formatters.grade(s.average)} / 20',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Text(s.periodLabel, style: const TextStyle(fontSize: 17)),
                      ],
                    ),
                  ),
                  gap12,
                  Row(
                    children: [
                      Expanded(child: StatTile(label: 'Plus forte', value: Formatters.grade(s.highest))),
                      const SizedBox(width: 12),
                      Expanded(child: StatTile(label: 'Plus faible', value: Formatters.grade(s.lowest))),
                    ],
                  ),
                  gap12,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('Élèves à 10 ou plus', style: TextStyle(fontSize: 17))),
                            Text(
                              '${(s.passRate * 100).round()} %',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: s.passRate,
                            minHeight: 12,
                            color: AppColors.green,
                            backgroundColor: AppColors.greySoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
