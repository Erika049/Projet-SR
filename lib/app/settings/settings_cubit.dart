import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/permissions/app_permissions.dart';
import '../../core/storage/local_storage.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.locale = const Locale('fr'),
    this.lowDataMode = true,
    this.darkMode = false,
    this.notificationsWanted = true,
    this.notificationsAllowed = false,
  });

  final Locale locale;

  /// « Mode faible consommation » : moins d'images, rafraîchissements manuels.
  final bool lowDataMode;

  /// Thème sombre (sinon thème clair).
  final bool darkMode;

  /// Choix de l'utilisateur dans l'application (interrupteur du profil).
  final bool notificationsWanted;

  /// Autorisation accordée par le téléphone.
  final bool notificationsAllowed;

  /// Les notifications push sont réellement reçues : voulues ET autorisées.
  bool get notificationsOn => notificationsWanted && notificationsAllowed;

  SettingsState copyWith({
    Locale? locale,
    bool? lowDataMode,
    bool? darkMode,
    bool? notificationsWanted,
    bool? notificationsAllowed,
  }) => SettingsState(
    locale: locale ?? this.locale,
    lowDataMode: lowDataMode ?? this.lowDataMode,
    darkMode: darkMode ?? this.darkMode,
    notificationsWanted: notificationsWanted ?? this.notificationsWanted,
    notificationsAllowed: notificationsAllowed ?? this.notificationsAllowed,
  );

  @override
  List<Object?> get props => [locale, lowDataMode, darkMode, notificationsWanted, notificationsAllowed];
}

/// Préférences de l'appareil : langue, thème, notifications, mode faible consommation.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._storage, this._permissions)
    : super(
        SettingsState(
          locale: Locale(_storage.getString(LocalStorage.keyLocale) ?? 'fr'),
          lowDataMode: _storage.getBool(LocalStorage.keyLowData) ?? true,
          darkMode: _storage.getBool(LocalStorage.keyDarkMode) ?? false,
          notificationsWanted: _storage.getBool(LocalStorage.keyNotifications) ?? true,
        ),
      );

  final LocalStorage _storage;
  final AppPermissions _permissions;

  bool get isFrench => state.locale.languageCode == 'fr';

  /// La demande d'autorisation des notifications doit-elle encore être présentée ?
  bool get shouldPromptNotifications => !(_storage.getBool(LocalStorage.keyNotificationsPrompted) ?? false);

  Future<void> setLocale(String code) async {
    await _storage.setString(LocalStorage.keyLocale, code);
    emit(state.copyWith(locale: Locale(code)));
  }

  Future<void> setLowDataMode(bool value) async {
    await _storage.setBool(LocalStorage.keyLowData, value);
    emit(state.copyWith(lowDataMode: value));
  }

  Future<void> setDarkMode(bool value) async {
    await _storage.setBool(LocalStorage.keyDarkMode, value);
    emit(state.copyWith(darkMode: value));
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

  /// L'utilisateur a choisi « Plus tard » lors de la première demande.
  Future<void> postponeNotifications() => _storage.setBool(LocalStorage.keyNotificationsPrompted, true);

  Future<bool> openPhoneSettings() => _permissions.openSettings();
}
