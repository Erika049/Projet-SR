import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_json.dart';
import '../../domain/entities/child.dart';
import '../models/child_model.dart';

abstract interface class ChildrenRemoteDataSource {
  Future<List<ChildModel>> getChildren();
  Future<List<LinkRequestModel>> getLinkRequests();
  Future<LinkRequestModel> linkChild(String code);
  Future<void> unlinkChild(String childId);
  Future<void> requestCorrection(String childId, String message);
}

/// Backend SchoolConnect :
/// - `GET /mes-enfants` : enfants liés (lien validé) avec classe, établissement, année et droits ;
/// - `GET|POST /mes-enfants/liaisons` : demandes de liaison par code, validées par le secrétariat ;
/// - `DELETE /mes-enfants/{eleveId}` : retrait d'un enfant.
class ChildrenApiDataSource implements ChildrenRemoteDataSource {
  const ChildrenApiDataSource(this._api);
  final ApiClient _api;

  static String? _name(Object? v, [String key = 'nom']) => v is Map ? v[key] as String? : v as String?;

  static LinkRequestModel _request(Map<String, dynamic> j) => LinkRequestModel(
    id: j['id'] as String? ?? '',
    childName: j['eleveNom'] as String? ?? 'Élève',
    classe: [j['classe'], j['etablissement']].whereType<String>().join(' · '),
  );

  @override
  Future<List<ChildModel>> getChildren() async {
    final json = await _api.get('/mes-enfants');
    return [
      for (final j in ApiJson.list(json))
        () {
          final eleve = j['eleve'] is Map ? ApiJson.map(j['eleve']) : j;
          return ChildModel(
            id: (j['eleveId'] ?? eleve['id']) as String,
            prenom: eleve['prenom'] as String? ?? '',
            nom: eleve['nom'] as String? ?? '',
            classe: _name(j['classe']) ?? j['classeNom'] as String? ?? '',
            etablissement: _name(j['etablissement']) ?? j['etablissementNom'] as String? ?? '',
            anneeScolaire: _name(j['anneeScolaire'], 'libelle') ?? '',
            matricule: j['matricule'] as String?,
            rights: ChildRights(
              canView: j['peutConsulter'] as bool? ?? true,
              canPay: j['peutPayer'] as bool? ?? false,
              canJustify: j['peutJustifier'] as bool? ?? false,
            ),
          );
        }(),
    ];
  }

  @override
  Future<List<LinkRequestModel>> getLinkRequests() async =>
      ApiJson.list(await _api.get('/mes-enfants/liaisons')).map(_request).toList();

  @override
  Future<LinkRequestModel> linkChild(String code) async =>
      _request(ApiJson.map(await _api.post('/mes-enfants/liaisons', data: {'code': code.trim()})));

  @override
  Future<void> unlinkChild(String childId) => _api.delete('/mes-enfants/$childId');

  @override
  Future<void> requestCorrection(String childId, String message) =>
      notAvailableOnServer('La demande de correction');
}
