import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../../domain/entities/notifications.dart';
import '../state/notifications_cubits.dart';

/// Onglet « Alertes » du parent (CU-PAR-13).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<NotificationsCubit>()..load(), child: const _NotificationsView());
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  /// 0 = Tous, sinon index de l'enfant + 1.
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsCubit>().state;
    final children = context.watch<ChildrenCubit>().state.children;
    final cubit = context.read<NotificationsCubit>();

    return AppPage(
      title: 'Notifications',
      onRefresh: cubit.load,
      body: DataStateBuilder(
        state: state,
        onRetry: cubit.load,
        builder: (context, feed) {
          final childId = _filter == 0 ? null : children[_filter - 1].id;
          final items = feed.items.where((n) => childId == null || n.childId == null || n.childId == childId).toList();
          final unread = items.where((n) => !n.read).length;

          if (items.isEmpty && feed.fromCache) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  _OfflineBanner(feed: feed),
                  Expanded(
                    child: MessageView(
                      icon: Icons.notifications_none_rounded,
                      title: 'Aucune notification',
                      message: 'Les nouvelles notes, absences et paiements apparaîtront ici dès leur réception.',
                      actionLabel: 'Réessayer la connexion',
                      onAction: cubit.load,
                      footnote:
                          'Sans Internet, les alertes urgentes arrivent aussi par SMS. '
                          'Vos données déjà chargées restent accessibles.',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (feed.fromCache)
                _OfflineBanner(feed: feed)
              else
                InkWell(
                  onTap: () => context.push(Routes.parentPreferences),
                  child: const InfoBanner('Push et SMS activés', tone: StatusTone.success),
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
              SectionTitle('Aujourd’hui', trailing: unread == 0 ? null : '$unread nouvelle${unread > 1 ? 's' : ''}'),
              for (final n in items) ...[_NotificationCard(notification: n), gap12],
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: NavRow('Annonces et convocations', onTap: () => context.push(Routes.parentAnnouncements)),
              ),
              const HelpText('Hors connexion, les alertes déjà reçues restent visibles.'),
            ],
          );
        },
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.feed});
  final NotificationFeed feed;

  @override
  Widget build(BuildContext context) {
    final date = feed.lastUpdate;
    return InfoBanner.offline(
      date == null
          ? 'Hors connexion'
          : 'Hors connexion · dernière mise à jour le ${Formatters.shortDate(date)} à ${Formatters.time(date)}',
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final color = switch (n.type) {
      NotificationType.note || NotificationType.bulletin => AppColors.green,
      NotificationType.absence => AppColors.amber,
      _ => AppColors.navy,
    };
    return AppCard(
      onTap: n.type == NotificationType.absence || n.type == NotificationType.note
          ? () => context.go(Routes.parentTracking)
          : n.type == NotificationType.echeance
          ? () => context.go('${Routes.parentTracking}?tab=2')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(n.message, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Text(
            '${Formatters.time(n.date)} · ${n.channels.map((c) => c.label).join(' + ')}',
            style: TextStyle(fontSize: 15, color: color),
          ),
        ],
      ),
    );
  }
}
