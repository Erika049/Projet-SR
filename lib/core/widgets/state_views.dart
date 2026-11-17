import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../errors/failures.dart';
import 'app_button.dart';

/// Écran centré avec icône, titre, texte et action
/// (« Aucune notification », « Chargement impossible », « Session expirée »).
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(color: AppColors.greySoft, borderRadius: BorderRadius.circular(28)),
              child: Icon(icon, size: 38, color: AppColors.navy),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
            if (footnote != null) ...[
              const SizedBox(height: 14),
              Text(
                footnote!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Erreur de chargement avec bouton « Réessayer ».
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isNetwork = failure is NetworkFailure;
    return MessageView(
      icon: Icons.warning_amber_rounded,
      title: 'Chargement impossible',
      message: isNetwork
          ? 'Le réseau est trop lent ou indisponible. Vos données déjà chargées restent accessibles.'
          : failure.message,
      actionLabel: 'Réessayer',
      onAction: onRetry,
      footnote: 'Si le problème continue, contactez votre école.',
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(child: CircularProgressIndicator(color: AppColors.navy));
}
