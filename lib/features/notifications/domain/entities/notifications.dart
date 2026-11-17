import 'package:equatable/equatable.dart';

/// Types de notification (table `notification`).
enum NotificationType {
  absence('Absence'),
  note('Nouvelle note'),
  bulletin('Bulletin disponible'),
  echeance('Échéance de paiement'),
  annonce('Annonce');

  const NotificationType(this.label);
  final String label;
}

enum NotificationChannel {
  push('Push'),
  sms('SMS'),
  email('Email');

  const NotificationChannel(this.label);
  final String label;
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    required this.channels,
    this.childId,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime date;
  final List<NotificationChannel> channels;

  /// Enfant concerné (vue consolidée du parent).
  final String? childId;
  final bool read;

  @override
  List<Object?> get props => [id, type, title, message, date, channels, childId, read];
}

/// Liste des notifications, éventuellement servie depuis le cache local.
class NotificationFeed extends Equatable {
  const NotificationFeed({required this.items, this.fromCache = false, this.lastUpdate});

  final List<AppNotification> items;

  /// `true` : hors connexion, données déjà reçues.
  final bool fromCache;
  final DateTime? lastUpdate;

  @override
  List<Object?> get props => [items, fromCache, lastUpdate];
}

/// Préférences d'alertes d'un parent pour un enfant (CU-PAR-16).
class NotificationPreferences extends Equatable {
  const NotificationPreferences({required this.childId, required this.channels, required this.byType});

  /// Canal utilisé par défaut pour toutes les alertes de l'application.
  static const defaultChannel = NotificationChannel.push;

  /// Réglage initial : toutes les alertes en notification push, SMS et email désactivés.
  factory NotificationPreferences.defaults(String childId) => NotificationPreferences(
    childId: childId,
    channels: const {defaultChannel},
    byType: {
      for (final type in NotificationType.values) type: const {defaultChannel},
    },
  );

  final String childId;

  /// Canaux activés globalement.
  final Set<NotificationChannel> channels;

  /// Canaux utilisés pour chaque type d'alerte.
  final Map<NotificationType, Set<NotificationChannel>> byType;

  NotificationPreferences copyWith({
    Set<NotificationChannel>? channels,
    Map<NotificationType, Set<NotificationChannel>>? byType,
  }) => NotificationPreferences(childId: childId, channels: channels ?? this.channels, byType: byType ?? this.byType);

  @override
  List<Object?> get props => [childId, channels, byType];
}

// ───────────────────────────── Annonces ─────────────────────────────

enum AnnouncementKind { annonce, convocation }

/// Annonce ou convocation de l'établissement (table `annonce`, CU-PAR-14).
class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.summary,
    required this.kind,
    required this.publishedAt,
    this.content,
  });

  final String id;
  final String title;
  final String summary;
  final AnnouncementKind kind;
  final DateTime publishedAt;
  final String? content;

  @override
  List<Object?> get props => [id, title, summary, kind, publishedAt, content];
}
