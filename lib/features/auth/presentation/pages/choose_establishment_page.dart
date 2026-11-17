import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/establishment.dart';
import '../state/auth_form_cubits.dart';
import '../state/session_cubit.dart';
import '../widgets/auth_layout.dart';

/// Enseignant rattaché à plusieurs établissements (CU-ENS-01).
class ChooseEstablishmentPage extends StatelessWidget {
  const ChooseEstablishmentPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<EstablishmentsCubit>()..load(), child: const _ChooseView());
}

class _ChooseView extends StatefulWidget {
  const _ChooseView();

  @override
  State<_ChooseView> createState() => _ChooseViewState();
}

class _ChooseViewState extends State<_ChooseView> {
  Establishment? _selected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EstablishmentsCubit>().state;
    return AuthLayout(
      title: 'Choisir un établissement',
      subtitle: 'Votre compte est rattaché à plusieurs établissements. Lequel souhaitez-vous ouvrir ?',
      footer: AuthLink(
        text: 'Ce n’est pas votre compte ?',
        action: 'Se déconnecter',
        onTap: () => context.read<SessionCubit>().logout(),
      ),
      children: [
        DataStateBuilder(
          state: state,
          onRetry: context.read<EstablishmentsCubit>().load,
          builder: (context, list) {
            final selected = _selected ?? context.read<SessionCubit>().state.establishment ?? list.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in list) ...[
                  AppCard(
                    accent: e == selected,
                    onTap: () => setState(() => _selected = e),
                    child: Row(
                      children: [
                        Icon(
                          e == selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: e == selected ? AppColors.navy : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.nom, style: context.text.titleLarge),
                              const SizedBox(height: 6),
                              Text(
                                '${e.classesCount} classes${e.matiere == null ? '' : ' · ${e.matiere}'}',
                                style: context.text.bodySmall?.copyWith(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  gap12,
                ],
                gap12,
                AppButton(
                  label: 'Continuer',
                  onPressed: () => context.read<SessionCubit>().chooseEstablishment(selected),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
