import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/local_storage.dart';

class SettingsState extends Equatable {
  const SettingsState({this.locale = const Locale('fr'), this.lowDataMode = true});

  final Locale locale;

  /// « Mode faible consommation » : moins d'images, rafraîchissements manuels.
  final bool lowDataMode;

  @override
  List<Object?> get props => [locale, lowDataMode];
}

/// Préférences de l'appareil : langue (FR/EN) et mode faible consommation.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._storage)
      : super(SettingsState(
          locale: Locale(_storage.getString(LocalStorage.keyLocale) ?? 'fr'),
          lowDataMode: _storage.getBool(LocalStorage.keyLowData) ?? true,
        ));

  final LocalStorage _storage;

  bool get isFrench => state.locale.languageCode == 'fr';

  Future<void> setLocale(String code) async {
    await _storage.setString(LocalStorage.keyLocale, code);
    emit(SettingsState(locale: Locale(code), lowDataMode: state.lowDataMode));
  }

  Future<void> setLowDataMode(bool value) async {
    await _storage.setBool(LocalStorage.keyLowData, value);
    emit(SettingsState(locale: state.locale, lowDataMode: value));
  }
}
