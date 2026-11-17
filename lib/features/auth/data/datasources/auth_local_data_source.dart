import '../../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

/// Session conservée sur le téléphone.
class AuthLocalDataSource {
  const AuthLocalDataSource(this._storage);
  final LocalStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await _storage.setString(LocalStorage.keyToken, session.token);
    await _storage.setJson(LocalStorage.keyUser, session.user.toJson());
  }

  UserModel? readUser() {
    if (_storage.getString(LocalStorage.keyToken) == null) return null;
    final json = _storage.getJson(LocalStorage.keyUser);
    return json == null ? null : UserModel.fromJson(json);
  }

  Future<void> saveEstablishment(EstablishmentModel e) => _storage.setJson(LocalStorage.keyEstablishment, e.toJson());

  EstablishmentModel? readEstablishment() {
    final json = _storage.getJson(LocalStorage.keyEstablishment);
    return json == null ? null : EstablishmentModel.fromJson(json);
  }

  Future<void> clear() async {
    await _storage.remove(LocalStorage.keyToken);
    await _storage.remove(LocalStorage.keyUser);
    await _storage.remove(LocalStorage.keyEstablishment);
  }
}
