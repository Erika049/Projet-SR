import 'package:equatable/equatable.dart';

enum SyncStatus {
  enAttente('En attente'),
  brouillon('Brouillon'),
  envoye('Envoyé'),
  conflit('Conflit');

  const SyncStatus(this.label);
  final String label;
}

/// Élément de la file de synchronisation (« Appel · 3e A · 09 nov. »).
class SyncItem extends Equatable {
  const SyncItem({required this.id, required this.label, required this.status});

  final String id;
  final String label;
  final SyncStatus status;

  @override
  List<Object?> get props => [id, label, status];
}

class SyncOverview extends Equatable {
  const SyncOverview({required this.items, this.lastSync});

  final List<SyncItem> items;
  final DateTime? lastSync;

  List<SyncItem> get toSend =>
      items.where((i) => i.status == SyncStatus.enAttente || i.status == SyncStatus.brouillon).toList();
  List<SyncItem> get sent => items.where((i) => i.status == SyncStatus.envoye).toList();
  List<SyncItem> get conflicts => items.where((i) => i.status == SyncStatus.conflit).toList();

  /// Nombre affiché dans le profil (« 1 en attente »).
  int get pendingCount => items.where((i) => i.status == SyncStatus.enAttente).length;

  @override
  List<Object?> get props => [items, lastSync];
}
