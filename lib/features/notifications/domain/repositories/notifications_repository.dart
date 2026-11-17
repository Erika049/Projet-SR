import '../../../../core/utils/result.dart';
import '../entities/notifications.dart';

abstract interface class NotificationsRepository {
  /// Notifications reçues (CU-PAR-13). Hors connexion : dernières reçues.
  Future<Result<NotificationFeed>> getNotifications();
  Future<Result<void>> markAllRead();
  Future<Result<NotificationPreferences>> getPreferences(String childId);
  Future<Result<void>> savePreferences(NotificationPreferences preferences);
  Future<Result<List<Announcement>>> getAnnouncements();
}
