import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/mock_delay.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/sync_queue.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/sync_repository.dart';

/// S'appuie sur la [SyncQueue] locale alimentée par les appels et les notes
/// enregistrés hors connexion. L'envoi réel au serveur est simulé ici.
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._queue, this._network);

  final SyncQueue _queue;
  final NetworkInfo _network;

  final List<SyncItem> _sent = [const SyncItem(id: 'sent-1', label: 'Appel · 4e B · 06 nov.', status: SyncStatus.envoye)];
  final List<SyncItem> _conflicts = [
    const SyncItem(id: 'conflict-1', label: 'Note d’Amina Etame modifiée', status: SyncStatus.conflit),
  ];
  DateTime? _lastSync = DateTime.now().subtract(const Duration(hours: 2));

  SyncOverview _overview() => SyncOverview(
        lastSync: _lastSync,
        items: [
          for (final op in _queue.all)
            SyncItem(id: op.id, label: op.label, status: op.draft ? SyncStatus.brouillon : SyncStatus.enAttente),
          ..._sent,
          ..._conflicts,
        ],
      );

  @override
  Future<Result<SyncOverview>> getOverview() async => Ok(_overview());

  @override
  Future<Result<SyncOverview>> syncNow() => guard(() async {
        if (!await _network.isConnected) throw const NetworkException();
        await mockDelay(800);
        for (final op in _queue.all.where((op) => !op.draft)) {
          _sent.insert(0, SyncItem(id: op.id, label: op.label, status: SyncStatus.envoye));
          await _queue.remove(op.id);
        }
        _lastSync = DateTime.now();
        return _overview();
      });

  @override
  Future<Result<SyncOverview>> resolveConflict(String id, {required bool keepLocal}) => guard(() async {
        await mockDelay();
        _conflicts.removeWhere((c) => c.id == id);
        return _overview();
      });
}
