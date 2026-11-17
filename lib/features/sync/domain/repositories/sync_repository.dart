import '../../../../core/utils/result.dart';
import '../entities/sync_item.dart';

abstract interface class SyncRepository {
  Future<Result<SyncOverview>> getOverview();

  /// Envoie les éléments en attente (les brouillons restent sur le téléphone).
  Future<Result<SyncOverview>> syncNow();

  /// Résout un conflit en gardant la version du téléphone ([keepLocal]) ou celle du serveur.
  Future<Result<SyncOverview>> resolveConflict(String id, {required bool keepLocal});
}
