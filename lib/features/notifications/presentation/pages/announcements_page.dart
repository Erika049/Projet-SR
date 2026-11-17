import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/notifications.dart';
import '../state/notifications_cubits.dart';

/// « Annonces » et convocations de l'établissement (CU-PAR-14).
class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnnouncementsCubit>()..load(),
      child: Builder(
        builder: (context) {
          final state = context.watch<AnnouncementsCubit>().state;
          return AppPage(
            title: 'Annonces',
            onRefresh: context.read<AnnouncementsCubit>().load,
            body: DataStateBuilder(
              state: state,
              onRetry: context.read<AnnouncementsCubit>().load,
              builder: (context, list) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, _) => gap12,
                itemBuilder: (context, i) => _AnnouncementCard(item: list[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final convocation = item.kind == AnnouncementKind.convocation;
    return AppCard(
      onTap: item.content == null
          ? null
          : () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(item.summary, style: const TextStyle(color: AppColors.textSecondary)),
                        gap12,
                        Text(item.content!, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              StatusChip(
                convocation ? 'Convocation' : 'Annonce',
                tone: convocation ? StatusTone.warning : StatusTone.success,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.summary, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
