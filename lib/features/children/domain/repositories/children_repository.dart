import '../../../../core/utils/result.dart';
import '../entities/child.dart';

abstract interface class ChildrenRepository {
  /// Enfants rattachés et validés (CU-PAR-03, CU-PAR-04).
  Future<Result<List<Child>>> getChildren();

  /// Demandes de liaison en attente.
  Future<Result<List<LinkRequest>>> getLinkRequests();

  /// Lie un enfant via le code remis par l'école (CU-PAR-02).
  Future<Result<LinkRequest>> linkChild(String code);

  /// Se dissocier d'un enfant (CU-PAR-17).
  Future<Result<void>> unlinkChild(String childId);

  /// Demander une correction d'information (CU-PAR-17).
  Future<Result<void>> requestCorrection(String childId, String message);
}
