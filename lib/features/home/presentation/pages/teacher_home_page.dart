import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/state/session_cubit.dart';
import '../../../sync/presentation/state/sync_cubit.dart';
import '../../../timetable/domain/entities/course.dart';
import '../state/home_cubits.dart';

/// Accueil enseignant : cours en cours, mes classes, saisie des notes.
class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<TeacherHomeCubit>()..load(), child: const _TeacherHomeView());
}

class _TeacherHomeView extends StatelessWidget {
  const _TeacherHomeView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state.user;
    final state = context.watch<TeacherHomeCubit>().state;
    final lastSync = context.watch<SyncCubit>().state.data?.lastSync;
    final cubit = context.read<TeacherHomeCubit>();

    return AppPage(
      title: 'Bonjour, ${user?.greetingName ?? ''}',
      onRefresh: cubit.load,
      body: DataStateBuilder(
        state: state,
        onRetry: cubit.load,
        builder: (context, o) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              '${user?.specialite ?? ''} · ${Formatters.longDate(DateTime.now(), withYear: false)}',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            gap12,
            if (o.current != null) ...[_CurrentCourseCard(course: o.current!), gap20],
            SectionTitle(
              'Mes classes',
              trailing: 'Emploi du temps ›',
              onTrailingTap: () => context.push(Routes.teacherTimetable),
            ),
            AppCard(
              child: DividedColumn(
                children: [for (final c in o.classes) _ClassRow(teacherClass: c, ongoing: o.current?.classId == c.id)],
              ),
            ),
            gap12,
            if (o.classes.isEmpty)
              const HelpText('Aucune classe ne vous est encore affectée dans cet établissement.')
            else
              AppButton(
                label: 'Saisir des notes',
                onPressed: () => context.go(Routes.teacherGrades(o.current?.classId ?? o.classes.first.id)),
              ),
            InkWell(
              onTap: () => context.push(Routes.teacherSync),
              child: HelpText(
                lastSync == null
                    ? 'Synchronisation ›'
                    : 'Dernière synchronisation : ${_relativeDay(lastSync)} à ${Formatters.time(lastSync)} ›',
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeDay(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'aujourd’hui';
    return 'le ${DateFormat('dd/MM', 'fr_FR').format(d)}';
  }
}

class _CurrentCourseCard extends StatelessWidget {
  const _CurrentCourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final ongoing = course.isOngoing(DateTime.now());
    return HighlightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${ongoing ? 'EN COURS' : 'PROCHAIN COURS'} · ${Formatters.slot(course.start, course.end)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${course.className} · ${course.subject}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text('${course.studentCount} élèves · ${course.room}', style: const TextStyle(fontSize: 16)),
          gap12,
          AppButton(
            label: 'Faire l’appel',
            variant: AppButtonVariant.soft,
            onPressed: () => context.go(Routes.teacherRollCall(course.classId)),
          ),
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.teacherClass, required this.ongoing});

  final TeacherClass teacherClass;
  final bool ongoing;

  String get _next {
    if (ongoing) return 'En cours';
    final n = teacherClass.nextCourse;
    if (n == null) return 'Aucun cours prévu';
    final day = DateFormat('EEEE', 'fr_FR').format(n.start);
    return '${day[0].toUpperCase()}${day.substring(1)}, ${n.start.hour} h';
  }

  @override
  Widget build(BuildContext context) {
    final c = teacherClass;
    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.name, style: Theme.of(context).textTheme.titleLarge),
              for (final (icon, label, route) in [
                (Icons.check_rounded, 'Faire l’appel', Routes.teacherRollCall(c.id)),
                (Icons.edit_note_rounded, 'Saisir des notes', Routes.teacherGrades(c.id)),
              ])
                ListTile(
                  leading: Icon(icon, color: AppColors.navy),
                  title: Text(label),
                  onTap: () {
                    Navigator.pop(sheet);
                    context.go(route);
                  },
                ),
              for (final (icon, label, route) in [
                (Icons.comment_outlined, 'Appréciations', Routes.teacherAppreciations(c.id)),
                (Icons.bar_chart_rounded, 'Statistiques', Routes.teacherStats(c.id)),
              ])
                ListTile(
                  leading: Icon(icon, color: AppColors.navy),
                  title: Text(label),
                  onTap: () {
                    Navigator.pop(sheet);
                    context.push(route);
                  },
                ),
            ],
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text(
                  '${c.studentCount} élèves · $_next',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
