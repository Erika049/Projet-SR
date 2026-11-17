import 'dart:convert';

import 'local_storage.dart';

/// Opération enregistrée hors connexion, en attente d'envoi au serveur
/// (appel, feuille de notes). Lue par la fonctionnalité `sync`.
class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.kind,
    required this.label,
    required this.draft,
    required this.createdAt,
    required this.payload,
  });

  final String id;

  /// « appel » ou « notes ».
  final String kind;

  /// « Appel · 3e A · 09 nov. »
  final String label;

  /// `true` : brouillon non soumis ; `false` : prêt à envoyer.
  final bool draft;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'label': label,
        'draft': draft,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> j) => PendingOperation(
        id: j['id'] as String,
        kind: j['kind'] as String,
        label: j['label'] as String,
        draft: j['draft'] as bool,
        createdAt: DateTime.parse(j['createdAt'] as String),
        payload: (j['payload'] as Map).cast<String, dynamic>(),
      );
}

/// File d'attente persistante des opérations hors connexion.
class SyncQueue {
  SyncQueue(this._storage);

  final LocalStorage _storage;
  static const _key = 'sync.queue';

  List<PendingOperation> get all {
    final raw = _storage.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => PendingOperation.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ajoute ou remplace (même id) une opération.
  Future<void> put(PendingOperation op) async {
    final list = all..removeWhere((e) => e.id == op.id);
    await _save([...list, op]);
  }

  Future<void> remove(String id) async => _save(all..removeWhere((e) => e.id == id));

  Future<void> _save(List<PendingOperation> list) =>
      _storage.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
}
