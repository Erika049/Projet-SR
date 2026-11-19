import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_json.dart';
import '../../domain/entities/parent_overview.dart';

abstract interface class HomeRemoteDataSource {
  Future<ParentOverview> getParentOverview();
}

/// Backend SchoolConnect : l'accueil parent est composé à partir de plusieurs routes.
/// - Résumé par enfant : moyenne de l'année (`/mes-enfants/{id}/notes`, pondérée par les coefficients)
///   et absences sans justificatif (`/mes-enfants/{id}/presences`).
/// - « À ne pas manquer » : notifications non lues (absences, paiements).
class HomeApiDataSource implements HomeRemoteDataSource {
  const HomeApiDataSource(this._api);
  final ApiClient _api;

  Future<ChildSummary> _summary(String childId) async {
    final notes = ApiJson.list(await _api.get('/mes-enfants/$childId/notes'));
    var sum = 0.0;
    var coefs = 0.0;
    for (final m in notes) {
      final avg = ApiJson.toDouble(m['moyenne']);
      if (avg == null) continue;
      final coef = ApiJson.toDouble(m['coefficient']) ?? 1;
      sum += avg * coef;
      coefs += coef;
    }
    final presences = ApiJson.list(await _api.get('/mes-enfants/$childId/presences'));
    final toJustify = presences.where((p) => p['statut'] == 'ABSENT' && p['justificatif'] == null).length;
    return ChildSummary(childId: childId, average: coefs == 0 ? null : sum / coefs, absencesToJustify: toJustify);
  }

  @override
  Future<ParentOverview> getParentOverview() async {
    final children = ApiJson.list(await _api.get('/mes-enfants'));
    final summaries = await Future.wait([for (final c in children) _summary(c['eleveId'] as String)]);

    final page = ApiJson.map(
      await _api.get('/mes-notifications', query: {'nonLues': true, 'page': 0, 'taille': 10}),
    );
    final highlights = <Highlight>[];
    for (final n in ApiJson.list(page['elements'])) {
      final kind = switch (n['type']) {
        'ABSENCE' || 'RETARD' || 'SORTIE_ANTICIPEE' || 'JUSTIFICATIF_TRAITE' => HighlightKind.absence,
        'PAIEMENT_ENREGISTRE' || 'PAIEMENT_ANNULE' || 'RELANCE_IMPAYE' || 'DECLARATION_PAIEMENT_TRAITEE' =>
          HighlightKind.paiement,
        _ => null,
      };
      if (kind == null) continue;
      highlights.add(Highlight(kind: kind, text: n['titre'] as String? ?? '', childId: n['eleveId'] as String?));
      if (highlights.length == 3) break;
    }
    return ParentOverview(summaries: summaries, highlights: highlights);
  }
}
