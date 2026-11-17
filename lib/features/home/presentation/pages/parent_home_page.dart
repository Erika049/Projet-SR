import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/state/session_cubit.dart';
import '../../../children/domain/entities/child.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../../domain/entities/parent_overview.dart';
import '../state/home_cubits.dart';

/// Accueil parent : vue consolidée de tous les enfants (CU-PAR-03).
class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<ParentHomeCubit>()..load(), child: const _ParentHomeView());
}

class _ParentHomeView extends StatefulWidget {
  const _ParentHomeView();

  @override
  State<_ParentHomeView> createState() => _ParentHomeViewState();
}

class _ParentHomeViewState extends State<_ParentHomeView> {
  int _filter = 0; // 0 = Tous

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state.user;
    final childrenState = context.watch<ChildrenCubit>().state;
    final overview = context.watch<ParentHomeCubit>().state;

    Future<void> refresh() async {
      await Future.wait([context.read<ParentHomeCubit>().load(), context.read<ChildrenCubit>().load()]);
    }

    return AppPage(
      eyebrow: 'SCHOOLCONNECT · PARENT',
      title: 'Bonjour, ${user?.greetingName ?? ''}',
      onRefresh: refresh,
      body: Builder(
        builder: (context) {
          if (childrenState.children.isEmpty && childrenState.status == ViewStatus.success) {
            return MessageView(
              icon: Icons.family_restroom_rounded,
              title: 'Aucun enfant lié',
              message: 'Saisissez le code remis par l’école pour suivre votre enfant.',
              actionLabel: 'Lier un enfant',
              onAction: () => context.push(Routes.parentLinkChild),
            );
          }
          return DataStateBuilder(
            state: overview,
            onRetry: refresh,
            builder: (context, data) {
              final children = childrenState.children;
              final shown = _filter == 0 ? children : [children[_filter - 1]];
              final highlights = data.highlights
                  .where((h) => _filter == 0 || h.childId == null || h.childId == children[_filter - 1].id)
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    Formatters.longDate(DateTime.now()),
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  gap12,
                  if (children.length > 1) ...[
                    PillSelector(
                      labels: ['Tous', for (final c in children) c.prenom],
                      selected: _filter,
                      onChanged: (i) => setState(() => _filter = i),
                    ),
                    gap12,
                  ],
                  for (final (i, c) in shown.indexed) ...[
                    _ChildCard(child: c, summary: data.summaryOf(c.id), accent: i == 0),
                    gap12,
                  ],
                  if (highlights.isNotEmpty) ...[
                    const SectionTitle('À ne pas manquer'),
                    AppCard(
                      child: DividedColumn(children: [for (final h in highlights) _HighlightRow(highlight: h)]),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.summary, required this.accent});

  final Child child;
  final ChildSummary? summary;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return AppCard(
      accent: accent,
      onTap: () => context.push(Routes.parentChild(child.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(child.fullName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${child.classe} · ${child.etablissement}',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          if (s != null) ...[
            gap12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (s.gradesPublished && s.average != null)
                  StatusChip('Moy. ${Formatters.grade(s.average!)} / 20')
                else
                  StatusChip('${s.periodLabel} : notes non publiées', tone: StatusTone.warning),
                if (s.absencesToJustify > 0)
                  StatusChip(
                    '${s.absencesToJustify} absence${s.absencesToJustify > 1 ? 's' : ''} à justifier',
                    tone: StatusTone.danger,
                    onTap: () {
                      context.read<ChildrenCubit>().select(child.id);
                      context.go('${Routes.parentTracking}?tab=1');
                    },
                  )
                else
                  const StatusChip('Aucune alerte'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight});
  final Highlight highlight;

  @override
  Widget build(BuildContext context) {
    final (color, tab) = switch (highlight.kind) {
      HighlightKind.absence => (AppColors.amber, 1),
      HighlightKind.note => (AppColors.green, 0),
      HighlightKind.paiement => (AppColors.navy, 2),
    };
    return InkWell(
      onTap: () {
        if (highlight.childId != null) context.read<ChildrenCubit>().select(highlight.childId!);
        context.go('${Routes.parentTracking}?tab=$tab');
      },
      child: Text(highlight.text, style: TextStyle(fontSize: 17, color: color)),
    );
  }
}
