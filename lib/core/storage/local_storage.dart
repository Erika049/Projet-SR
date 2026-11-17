import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stockage local clé/valeur : préférences, session et cache hors connexion.
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const keyToken = 'auth.token';
  static const keyUser = 'auth.user';
  static const keyEstablishment = 'auth.establishment';
  static const keyLocale = 'settings.locale';
  static const keyLowData = 'settings.lowData';
  static const keyDarkMode = 'settings.darkMode';
  static const keyNotifications = 'settings.notifications';

  /// `true` une fois la demande d'autorisation des notifications présentée sur ce téléphone.
  static const keyNotificationsPrompted = 'settings.notificationsPrompted';

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setJson(String key, Map<String, dynamic> value) => _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);
}
