import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Réponse du téléphone à une demande d'autorisation.
enum PermissionResult {
  granted,
  denied,

  /// Refus définitif : seule la page « Paramètres » du téléphone permet de changer d'avis.
  permanentlyDenied;

  bool get isGranted => this == granted;
}

/// Autorisations système demandées par l'application (notifications, fichiers).
abstract interface class AppPermissions {
  Future<PermissionResult> notificationStatus();
  Future<PermissionResult> requestNotifications();

  /// Accès aux fichiers du téléphone (images, PDF) pour joindre un justificatif.
  Future<PermissionResult> filesStatus();
  Future<PermissionResult> requestFiles();

  /// Ouvre la page de l'application dans les paramètres du téléphone.
  Future<bool> openSettings();
}

/// Implémentation reliée au téléphone via `permission_handler`.
///
/// Fichiers : Android 13+ → `READ_MEDIA_IMAGES` (permission « photos ») ;
/// Android ≤ 12 → `READ_EXTERNAL_STORAGE` (permission « storage ») ;
/// iOS → photothèque.
class DeviceAppPermissions implements AppPermissions {
  const DeviceAppPermissions();

  static PermissionResult _map(PermissionStatus s) => switch (s) {
    PermissionStatus.granted || PermissionStatus.limited || PermissionStatus.provisional => PermissionResult.granted,
    PermissionStatus.permanentlyDenied || PermissionStatus.restricted => PermissionResult.permanentlyDenied,
    PermissionStatus.denied => PermissionResult.denied,
  };

  @override
  Future<PermissionResult> notificationStatus() async => _map(await Permission.notification.status);

  @override
  Future<PermissionResult> requestNotifications() async => _map(await Permission.notification.request());

  @override
  Future<PermissionResult> filesStatus() async {
    final photos = _map(await Permission.photos.status);
    if (photos.isGranted || !Platform.isAndroid) return photos;
    final storage = _map(await Permission.storage.status);
    return storage.isGranted ? storage : photos;
  }

  @override
  Future<PermissionResult> requestFiles() async {
    final photos = _map(await Permission.photos.request());
    if (photos.isGranted || !Platform.isAndroid) return photos;
    // Android ≤ 12 : la permission « photos » n'existe pas, on passe par le stockage.
    final storage = _map(await Permission.storage.request());
    if (storage.isGranted) return storage;
    return photos == PermissionResult.permanentlyDenied ? photos : storage;
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
