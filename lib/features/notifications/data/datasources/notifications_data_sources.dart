import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/notifications.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAllRead();
  Future<NotificationPreferences> getPreferences(String childId);
  Future<void> savePreferences(NotificationPreferences preferences);
  Future<List<Announcement>> getAnnouncements();
}

/// Cache des notifications : « Hors connexion, les alertes déjà reçues restent visibles ».
class NotificationsLocalDataSource {
  const NotificationsLocalDataSource(this._storage);
  final LocalStorage _storage;

  static const _key = 'cache.notifications';
  static const _keyDate = 'cache.notifications.date';

  Future<void> save(List<AppNotification> items) async {
    await _storage.setString(
      _key,
      jsonEncode([
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
      ]),
    );
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

/// Backend SchoolConnect : `GET /mes-notifications`, `PATCH /mes-notifications/lues`.
///
/// Les annonces de l'établissement sont les notifications de type MESSAGE_ETABLISSEMENT.
/// Les préférences d'alertes n'existent pas dans l'API : elles restent sur le téléphone.
class NotificationsApiDataSource implements NotificationsRemoteDataSource {
  NotificationsApiDataSource(this._api, this._storage);

  final ApiClient _api;
  final LocalStorage _storage;

  static String _prefsKey(String childId) => 'notifications.preferences.$childId';

  static NotificationType _type(Object? v) => switch (v) {
    'ABSENCE' || 'RETARD' || 'SORTIE_ANTICIPEE' || 'JUSTIFICATIF_TRAITE' => NotificationType.absence,
    'PAIEMENT_ENREGISTRE' || 'PAIEMENT_ANNULE' || 'RELANCE_IMPAYE' || 'DECLARATION_PAIEMENT_TRAITEE' =>
      NotificationType.echeance,
    _ => NotificationType.annonce,
  };

  Future<List<Map<String, dynamic>>> _fetch() async {
    final page = ApiJson.map(await _api.get('/mes-notifications', query: {'page': 0, 'taille': 50}));
    return ApiJson.list(page['elements']);
  }

  @override
  Future<List<AppNotification>> getNotifications() async => [
    for (final n in await _fetch())
      AppNotification(
        id: n['id'] as String,
        type: _type(n['type']),
        title: n['titre'] as String? ?? '',
        message: n['message'] as String? ?? '',
        date: ApiJson.parseDate(n['creeLe']) ?? DateTime.now(),
        channels: const [NotificationPreferences.defaultChannel],
        childId: n['eleveId'] as String?,
        read: n['lueLe'] != null,
      ),
  ];

  @override
  Future<void> markAllRead() => _api.patch('/mes-notifications/lues');

  @override
  Future<NotificationPreferences> getPreferences(String childId) async {
    final json = _storage.getJson(_prefsKey(childId));
    if (json == null) return NotificationPreferences.defaults(childId);
    Set<NotificationChannel> channels(Object? list) => {
      for (final c in (list as List? ?? const [])) NotificationChannel.values.byName(c as String),
    };
    return NotificationPreferences(
      childId: childId,
      channels: channels(json['channels']),
      byType: {
        for (final t in NotificationType.values) t: channels(ApiJson.map(json['byType'])[t.name]),
      },
    );
  }

  @override
  Future<void> savePreferences(NotificationPreferences p) => _storage.setJson(_prefsKey(p.childId), {
    'channels': [for (final c in p.channels) c.name],
    'byType': {
      for (final e in p.byType.entries) e.key.name: [for (final c in e.value) c.name],
    },
  });

  @override
  Future<List<Announcement>> getAnnouncements() async => [
    for (final n in await _fetch())
      if (n['type'] == 'MESSAGE_ETABLISSEMENT')
        Announcement(
          id: n['id'] as String,
          title: n['titre'] as String? ?? '',
          summary: n['message'] as String? ?? '',
          kind: AnnouncementKind.annonce,
          publishedAt: ApiJson.parseDate(n['creeLe']) ?? DateTime.now(),
          content: n['message'] as String?,
        ),
  ];
}
