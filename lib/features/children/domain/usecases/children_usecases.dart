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

  /// Format attendu : SC-XXXX-XX
  static final _format = RegExp(r'^SC-[A-Z0-9]{4}-[A-Z0-9]{2}$');

  @override
  Future<Result<LinkRequest>> call(String code) async {
    final normalized = code.trim().toUpperCase();
    if (!_format.hasMatch(normalized)) {
      return const Err(ValidationFailure('Code invalide. Format attendu : SC-XXXX-XX'));
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
