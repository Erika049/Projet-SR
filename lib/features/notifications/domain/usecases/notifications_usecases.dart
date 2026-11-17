import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/notifications.dart';
import '../repositories/notifications_repository.dart';

class GetNotifications implements UseCase<NotificationFeed, NoParams> {
  const GetNotifications(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Result<NotificationFeed>> call(NoParams _) => _repo.getNotifications();
}

class MarkNotificationsRead implements UseCase<void, NoParams> {
  const MarkNotificationsRead(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Result<void>> call(NoParams _) => _repo.markAllRead();
}

class GetNotificationPreferences implements UseCase<NotificationPreferences, String> {
  const GetNotificationPreferences(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Result<NotificationPreferences>> call(String childId) => _repo.getPreferences(childId);
}

class SaveNotificationPreferences implements UseCase<void, NotificationPreferences> {
  const SaveNotificationPreferences(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Result<void>> call(NotificationPreferences p) async {
    // Les absences doivent toujours pouvoir être signalées (objectif : < 1 h).
    if ((p.byType[NotificationType.absence] ?? const {}).isEmpty) {
      return const Err(ValidationFailure('Gardez au moins un canal pour les absences.'));
    }
    return _repo.savePreferences(p);
  }
}

class GetAnnouncements implements UseCase<List<Announcement>, NoParams> {
  const GetAnnouncements(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Result<List<Announcement>>> call(NoParams _) => _repo.getAnnouncements();
}
