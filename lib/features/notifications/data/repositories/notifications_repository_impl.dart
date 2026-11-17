import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notifications.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_sources.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote, this._local, this._network);

  final NotificationsRemoteDataSource _remote;
  final NotificationsLocalDataSource _local;
  final NetworkInfo _network;

  @override
  Future<Result<NotificationFeed>> getNotifications() async {
    if (await _network.isConnected) {
      final result = await guard(_remote.getNotifications);
      if (result case Ok(:final value)) {
        await _local.save(value);
        return Ok(NotificationFeed(items: value, lastUpdate: DateTime.now()));
      }
    }
    // Hors connexion ou erreur réseau : on sert le cache.
    try {
      final cached = _local.read();
      return Ok(NotificationFeed(items: cached.items, fromCache: true, lastUpdate: cached.date));
    } on CacheException {
      return const Ok(NotificationFeed(items: [], fromCache: true));
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<void>> markAllRead() => guard(_remote.markAllRead);

  @override
  Future<Result<NotificationPreferences>> getPreferences(String childId) =>
      guard(() => _remote.getPreferences(childId));

  @override
  Future<Result<void>> savePreferences(NotificationPreferences preferences) =>
      guard(() => _remote.savePreferences(preferences));

  @override
  Future<Result<List<Announcement>>> getAnnouncements() => guard(_remote.getAnnouncements);
}
