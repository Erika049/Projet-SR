import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/child.dart';
import '../state/children_cubit.dart';
import '../widgets/child_selector.dart';
import 'link_child_page.dart';

/// « Mes enfants et droits ».
class MyChildrenPage extends StatelessWidget {
  const MyChildrenPage({super.key});

  Future<Child?> _pick(BuildContext context, List<Child> children) async {
    if (children.length == 1) return children.first;
    return showModalBottomSheet<Child>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in children)
              ListTile(title: Text(c.label), onTap: () => Navigator.pop(context, c)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = context.watch<ChildrenCubit>().state.children;
    return AppPage(
      title: 'Mes enfants et droits',
      children: [
        for (final c in children) ...[
          AppCard(
            onTap: () => context.push(Routes.parentChild(c.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [for (final r in c.rights.labels) StatusChip(r)]),
              ],
            ),
          ),
          gap12,
        ],
        AppButton(label: 'Lier un autre enfant', onPressed: () => context.push(Routes.parentLinkChild)),
        gap12,
        AppButton.secondary(
          label: 'Se dissocier d’un enfant',
          onPressed: children.isEmpty
              ? null
              : () async {
                  final c = await _pick(context, children);
                  if (c != null && context.mounted) await confirmUnlink(context, c);
                },
        ),
        gap12,
        AppButton.secondary(
          label: 'Demander une correction',
          onPressed: children.isEmpty
              ? null
              : () async {
                  final c = await _pick(context, children);
                  if (c != null && context.mounted) await showCorrectionDialog(context, c);
                },
        ),
      ],
    );
  }
}
