import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/mock_delay.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/notifications.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAllRead();
  Future<NotificationPreferences> getPreferences(String childId);
  Future<void> savePreferences(NotificationPreferences preferences);
  Future<List<Announcement>> getAnnouncements();
}

/// Données de démonstration (maquettes « Notifications » et « Annonces »).
class NotificationsMockDataSource implements NotificationsRemoteDataSource {
  final Map<String, NotificationPreferences> _prefs = {};
  bool _read = false;

  @override
  Future<List<AppNotification>> getNotifications() async {
    await mockDelay();
    final today = DateTime.now();
    DateTime at(int h, int m) => DateTime(today.year, today.month, today.day, h, m);
    return [
      AppNotification(
        id: 'n1',
        childId: 'eleve-amina',
        type: NotificationType.note,
        title: 'Une note a été publiée',
        message: 'Amina · 16/20 en mathématiques. Séquence 1, coef. 4.',
        date: at(9, 20),
        channels: const [NotificationChannel.push],
        read: _read,
      ),
      AppNotification(
        id: 'n2',
        childId: 'eleve-amina',
        type: NotificationType.absence,
        title: 'Absence signalée',
        message: 'Amina · Mathématiques, 8 h – 9 h. Vous pouvez justifier l’absence.',
        date: at(8, 15),
        channels: const [NotificationChannel.push, NotificationChannel.sms],
        read: _read,
      ),
      AppNotification(
        id: 'n3',
        type: NotificationType.echeance,
        title: 'Échéance de scolarité',
        message: '45 000 FCFA à régler avant le 30 novembre 2026.',
        date: at(7, 30),
        channels: const [NotificationChannel.push, NotificationChannel.sms],
        read: _read,
      ),
    ];
  }

  @override
  Future<void> markAllRead() async {
    await mockDelay(150);
    _read = true;
  }

  @override
  Future<NotificationPreferences> getPreferences(String childId) async {
    await mockDelay(300);
    const push = NotificationChannel.push;
    const sms = NotificationChannel.sms;
    return _prefs[childId] ??
        NotificationPreferences(
          childId: childId,
          channels: const {push, sms},
          byType: const {
            NotificationType.absence: {push, sms},
            NotificationType.note: {push},
            NotificationType.bulletin: {push},
            NotificationType.echeance: {push, sms},
            NotificationType.annonce: {push},
          },
        );
  }

  @override
  Future<void> savePreferences(NotificationPreferences preferences) async {
    await mockDelay();
    _prefs[preferences.childId] = preferences;
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    await mockDelay();
    return [
      Announcement(
        id: 'a1',
        title: 'Réunion des parents',
        summary: 'Samedi 21 novembre, 9 h · Salle polyvalente',
        kind: AnnouncementKind.convocation,
        publishedAt: DateTime(2026, 11, 10),
        content: 'Les parents d’élèves sont convoqués à la réunion trimestrielle. Présence obligatoire.',
      ),
      Announcement(
        id: 'a2',
        title: 'Remise des bulletins',
        summary: 'Séquence 1 · mercredi 25 novembre',
        kind: AnnouncementKind.annonce,
        publishedAt: DateTime(2026, 11, 9),
      ),
      Announcement(
        id: 'a3',
        title: 'Rappel de scolarité',
        summary: '2e versement avant le 30 novembre.',
        kind: AnnouncementKind.annonce,
        publishedAt: DateTime(2026, 11, 2),
      ),
    ];
  }
}

/// Cache des notifications : « Hors connexion, les alertes déjà reçues restent visibles ».
class NotificationsLocalDataSource {
  const NotificationsLocalDataSource(this._storage);
  final LocalStorage _storage;

  static const _key = 'cache.notifications';
  static const _keyDate = 'cache.notifications.date';

  Future<void> save(List<AppNotification> items) async {
    await _storage.setString(_key, jsonEncode([
      for (final n in items)
        {
          'id': n.id,
          'type': n.type.name,
          'title': n.title,
          'message': n.message,
          'date': n.date.toIso8601String(),
          'channels': [for (final c in n.channels) c.name],
          'childId': n.childId,
          'read': n.read,
        },
    ]));
    await _storage.setString(_keyDate, DateTime.now().toIso8601String());
  }

  ({List<AppNotification> items, DateTime? date}) read() {
    final raw = _storage.getString(_key);
    if (raw == null) throw const CacheException();
    final date = _storage.getString(_keyDate);
    return (
      date: date == null ? null : DateTime.parse(date),
      items: [
        for (final j in jsonDecode(raw) as List)
          AppNotification(
            id: j['id'] as String,
            type: NotificationType.values.byName(j['type'] as String),
            title: j['title'] as String,
            message: j['message'] as String,
            date: DateTime.parse(j['date'] as String),
            channels: [for (final c in j['channels'] as List) NotificationChannel.values.byName(c as String)],
            childId: j['childId'] as String?,
            read: j['read'] as bool,
          ),
      ],
    );
  }
}
