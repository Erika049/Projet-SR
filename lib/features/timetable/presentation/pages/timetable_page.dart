import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../state/timetable_cubit.dart';

/// « Emploi du temps » de l'enseignant (CU-ENS-02).
class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<TimetableCubit>()..load(), child: const _TimetableView());
}

class _TimetableView extends StatefulWidget {
  const _TimetableView();

  @override
  State<_TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<_TimetableView> {
  static const _days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];
  int _day = (DateTime.now().weekday - 1).clamp(0, 4);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TimetableCubit>().state;
    return AppPage(
      eyebrow: 'SCHOOLCONNECT · ENSEIGNANT',
      title: 'Emploi du temps',
      children: [
        PillSelector(labels: _days, selected: _day, onChanged: (i) => setState(() => _day = i)),
        gap12,
        DataStateBuilder(
          state: state,
          onRetry: context.read<TimetableCubit>().load,
          builder: (context, week) {
            final courses = week.where((c) => c.start.weekday == _day + 1).toList()
              ..sort((a, b) => a.start.compareTo(b.start));
            final date = week.isEmpty
                ? null
                : DateTime(week.first.start.year, week.first.start.month, week.first.start.day)
                    .subtract(Duration(days: week.first.start.weekday - 1))
                    .add(Duration(days: _day));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (date != null)
                  Text(Formatters.longDate(date, withYear: false),
                      style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                gap12,
                for (final c in courses) ...[
                  AppCard(
                    accent: c.isOngoing(DateTime.now()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.slot(c.start, c.end),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Text('${c.className} · ${c.subject}',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('${c.studentCount} élèves · ${c.room}',
                            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  gap12,
                ],
                HelpText(courses.isEmpty ? 'Aucun cours ce jour.' : 'Pas d’autre cours ce jour.'),
              ],
            );
          },
        ),
      ],
    );
  }
}
