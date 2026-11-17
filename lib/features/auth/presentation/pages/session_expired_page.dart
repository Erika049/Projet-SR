import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/widgets.dart';
import '../state/session_cubit.dart';

class SessionExpiredPage extends StatelessWidget {
  const SessionExpiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MessageView(
        icon: Icons.person_outline_rounded,
        title: 'Session expirée',
        message: 'Pour protéger vos données, reconnectez-vous.',
        actionLabel: 'Se reconnecter',
        // Déconnexion → le routeur renvoie vers l'écran de connexion.
        // Les brouillons hors connexion ne sont pas effacés.
        onAction: () => context.read<SessionCubit>().logout(),
        footnote: 'Vos brouillons non envoyés sont conservés sur ce téléphone.',
      ),
    );
  }
}
