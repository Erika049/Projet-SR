import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/permissions/app_permissions.dart';
import '../di/injection.dart';
import 'settings_cubit.dart';

/// Refus définitif : proposer d'ouvrir les paramètres du téléphone.
Future<void> _offerSettings(BuildContext context, {required String title, required String message}) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(fontSize: 15, height: 1.4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ouvrir les paramètres')),
      ],
    ),
  );
  if (open == true) await sl<AppPermissions>().openSettings();
}

/// Première connexion ou inscription : affiche directement la demande
/// d'autorisation des notifications du téléphone (une seule fois).
Future<void> promptNotificationsFirstTime(BuildContext context) async {
  if (!context.read<SettingsCubit>().shouldPromptNotifications) return;
  await enableNotifications(context);
}

/// Active les notifications (interrupteur du profil ou première demande).
/// Retourne `true` si le téléphone les a autorisées.
Future<bool> enableNotifications(BuildContext context) async {
  final settings = context.read<SettingsCubit>();
  final result = await settings.enableNotifications();
  if (!context.mounted) return result.isGranted;
  switch (result) {
    case PermissionResult.granted:
      context.showMessage('Notifications activées.');
    case PermissionResult.denied:
      context.showMessage('Notifications non autorisées.', error: true);
    case PermissionResult.permanentlyDenied:
      await _offerSettings(
        context,
        title: 'Notifications bloquées',
        message:
            'Les notifications sont bloquées pour SchoolConnect. '
            'Ouvrez les paramètres du téléphone, puis Notifications, et autorisez-les.',
      );
  }
  return result.isGranted;
}

/// Vérifie (et demande si besoin) l'accès aux fichiers du téléphone avant de
/// choisir un justificatif. Retourne `true` si l'accès est autorisé.
Future<bool> ensureFilesPermission(BuildContext context) async {
  final permissions = sl<AppPermissions>();
  if ((await permissions.filesStatus()).isGranted) return true;
  if (!context.mounted) return false;

  final result = await permissions.requestFiles();
  if (!context.mounted) return result.isGranted;
  if (result == PermissionResult.permanentlyDenied) {
    await _offerSettings(
      context,
      title: 'Accès aux fichiers bloqué',
      message: 'Autorisez l’accès aux photos et fichiers de SchoolConnect dans les paramètres du téléphone.',
    );
  } else if (!result.isGranted) {
    context.showMessage('Accès aux fichiers refusé : impossible de joindre la preuve.', error: true);
  }
  return result.isGranted;
}
