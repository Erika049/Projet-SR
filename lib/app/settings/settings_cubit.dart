import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/permissions/app_permissions.dart';
import '../../core/storage/local_storage.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.locale = const Locale('fr'),
    this.lowDataMode = true,
    this.notificationsWanted = true,
    this.notificationsAllowed = false,
  });

  final Locale locale;

  /// « Mode faible consommation » : moins d'images, rafraîchissements manuels.
  final bool lowDataMode;

  /// Choix de l'utilisateur dans l'application (interrupteur du profil).
  final bool notificationsWanted;

  /// Autorisation accordée par le téléphone.
  final bool notificationsAllowed;

  /// Les notifications push sont réellement reçues : voulues ET autorisées.
  bool get notificationsOn => notificationsWanted && notificationsAllowed;

  SettingsState copyWith({
    Locale? locale,
    bool? lowDataMode,
    bool? notificationsWanted,
    bool? notificationsAllowed,
  }) => SettingsState(
    locale: locale ?? this.locale,
    lowDataMode: lowDataMode ?? this.lowDataMode,
    notificationsWanted: notificationsWanted ?? this.notificationsWanted,
    notificationsAllowed: notificationsAllowed ?? this.notificationsAllowed,
  );

  @override
  List<Object?> get props => [locale, lowDataMode, notificationsWanted, notificationsAllowed];
}

/// Préférences de l'appareil : notifications, mode faible consommation.
/// L'application est uniquement en français.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._storage, this._permissions)
    : super(
        SettingsState(
          lowDataMode: _storage.getBool(LocalStorage.keyLowData) ?? true,
          notificationsWanted: _storage.getBool(LocalStorage.keyNotifications) ?? true,
        ),
      );

  final LocalStorage _storage;
  final AppPermissions _permissions;

  /// La demande d'autorisation des notifications doit-elle encore être présentée ?
  bool get shouldPromptNotifications => !(_storage.getBool(LocalStorage.keyNotificationsPrompted) ?? false);

  Future<void> setLowDataMode(bool value) async {
    await _storage.setBool(LocalStorage.keyLowData, value);
    emit(state.copyWith(lowDataMode: value));
  }

  /// Relit l'autorisation du téléphone (au démarrage et au retour dans l'application,
  /// l'utilisateur ayant pu la changer dans les paramètres).
  Future<void> refreshNotificationPermission() async {
    final status = await _permissions.notificationStatus();
    emit(state.copyWith(notificationsAllowed: status.isGranted));
  }

  /// Active les notifications : demande l'autorisation au téléphone si besoin.
  /// Retourne la réponse du téléphone.
  Future<PermissionResult> enableNotifications() async {
    await _storage.setBool(LocalStorage.keyNotificationsPrompted, true);
    var status = await _permissions.notificationStatus();
    if (status == PermissionResult.denied) status = await _permissions.requestNotifications();
    await _storage.setBool(LocalStorage.keyNotifications, status.isGranted);
    emit(state.copyWith(notificationsWanted: status.isGranted, notificationsAllowed: status.isGranted));
    return status;
  }

  /// Désactive les notifications dans l'application (l'autorisation du téléphone reste inchangée).
  Future<void> disableNotifications() async {
    await _storage.setBool(LocalStorage.keyNotifications, false);
    emit(state.copyWith(notificationsWanted: false));
  }

  Future<bool> openPhoneSettings() => _permissions.openSettings();
}
