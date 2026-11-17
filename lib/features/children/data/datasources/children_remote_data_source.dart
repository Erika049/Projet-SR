import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/mock_delay.dart';
import '../../domain/entities/child.dart';
import '../models/child_model.dart';

abstract interface class ChildrenRemoteDataSource {
  Future<List<ChildModel>> getChildren();
  Future<List<LinkRequestModel>> getLinkRequests();
  Future<LinkRequestModel> linkChild(String code);
  Future<void> unlinkChild(String childId);
  Future<void> requestCorrection(String childId, String message);
}

/// Données de démonstration conformes aux maquettes (famille Etame).
/// Code de liaison accepté : SC-4F7K-92.
class ChildrenMockDataSource implements ChildrenRemoteDataSource {
  final _children = <ChildModel>[
    const ChildModel(
      id: 'eleve-amina',
      prenom: 'Amina',
      nom: 'Etame',
      classe: '3e A',
      etablissement: 'Lycée bilingue de Bafoussam',
      anneeScolaire: '2026–2027',
      matricule: 'LBB-26-0412',
      rights: ChildRights(canPay: true, canJustify: true),
    ),
    const ChildModel(
      id: 'eleve-junior',
      prenom: 'Junior',
      nom: 'Etame',
      classe: '6e B',
      etablissement: 'Lycée bilingue de Bafoussam',
      anneeScolaire: '2026–2027',
      rights: ChildRights(canPay: true, canJustify: true),
    ),
  ];

  final _requests = <LinkRequestModel>[];

  @override
  Future<List<ChildModel>> getChildren() async {
    await mockDelay();
    return List.of(_children);
  }

  @override
  Future<List<LinkRequestModel>> getLinkRequests() async {
    await mockDelay(200);
    return List.of(_requests);
  }

  @override
  Future<LinkRequestModel> linkChild(String code) async {
    await mockDelay();
    if (code != 'SC-4F7K-92') throw const ServerException('Code inconnu ou expiré. Contactez le secrétariat.');
    final request = LinkRequestModel(id: 'req-${_requests.length + 1}', childName: 'Paul Etame', classe: '4e C');
    _requests.add(request);
    return request;
  }

  @override
  Future<void> unlinkChild(String childId) async {
    await mockDelay();
    _children.removeWhere((c) => c.id == childId);
  }

  @override
  Future<void> requestCorrection(String childId, String message) => mockDelay();
}
