import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/child.dart';
import '../repositories/children_repository.dart';

class GetChildren implements UseCase<List<Child>, NoParams> {
  const GetChildren(this._repo);
  final ChildrenRepository _repo;

  @override
  Future<Result<List<Child>>> call(NoParams _) => _repo.getChildren();
}

class GetLinkRequests implements UseCase<List<LinkRequest>, NoParams> {
  const GetLinkRequests(this._repo);
  final ChildrenRepository _repo;

  @override
  Future<Result<List<LinkRequest>>> call(NoParams _) => _repo.getLinkRequests();
}

class LinkChild implements UseCase<LinkRequest, String> {
  const LinkChild(this._repo);
  final ChildrenRepository _repo;

  /// Code remis par le secrétariat : 8 lettres ou chiffres. Espaces et tirets sont ignorés
  /// (« QG9H-R36E » = « QG9HR36E »).
  static String normalize(String code) => code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  @override
  Future<Result<LinkRequest>> call(String code) async {
    final normalized = normalize(code);
    if (normalized.length != 8) {
      return const Err(ValidationFailure('Code invalide : il contient 8 lettres ou chiffres (ex. QG9H-R36E).'));
    }
    return _repo.linkChild(normalized);
  }
}

class UnlinkChild implements UseCase<void, String> {
  const UnlinkChild(this._repo);
  final ChildrenRepository _repo;

  @override
  Future<Result<void>> call(String childId) => _repo.unlinkChild(childId);
}

class RequestCorrection implements UseCase<void, ({String childId, String message})> {
  const RequestCorrection(this._repo);
  final ChildrenRepository _repo;

  @override
  Future<Result<void>> call(({String childId, String message}) p) async {
    if (p.message.trim().isEmpty) return const Err(ValidationFailure('Décrivez la correction demandée.'));
    return _repo.requestCorrection(p.childId, p.message.trim());
  }
}
