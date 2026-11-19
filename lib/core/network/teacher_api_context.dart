import '../errors/exceptions.dart';
import '../storage/local_storage.dart';
import 'api_client.dart';
import 'api_json.dart';

/// Classe + matière affectées à l'enseignant (`AffectationView`), avec les noms lisibles.
class TeacherAssignment {
  const TeacherAssignment({
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subject,
    required this.coefficient,
    required this.schoolYearId,
  });

  final String classId;
  final String className;
  final String subjectId;
  final String subject;
  final double coefficient;
  final String schoolYearId;
}

/// Élève d'une classe (`InscriptionView`).
class StudentRef {
  const StudentRef({required this.id, required this.name, this.classId = ''});
  final String id;
  final String name;
  final String classId;
}

/// Période de saisie des notes (`PeriodeView`).
class PeriodRef {
  const PeriodRef({required this.id, required this.label, required this.isSequence});
  final String id;
  final String label;
  final bool isSequence;
}

/// Contexte « enseignant » partagé par l'emploi du temps, l'appel et les notes :
/// établissement choisi, classes affectées, élèves et période en cours.
/// Les réponses sont gardées en mémoire tant que l'utilisateur et l'établissement ne changent pas.
class TeacherApiContext {
  TeacherApiContext(this._api, this._storage);

  final ApiClient _api;
  final LocalStorage _storage;

  String? _cacheKey;
  List<TeacherAssignment>? _assignments;
  final Map<String, List<StudentRef>> _students = {};
  final Map<String, PeriodRef> _periods = {};

  /// Établissement choisi à la connexion (écran « Choisir un établissement »).
  String get establishmentId {
    final id = _storage.getJson(LocalStorage.keyEstablishment)?['id'];
    if (id is! String || id.isEmpty) throw const ServerException('Choisissez d’abord un établissement.');
    return id;
  }

  void _refreshCache() {
    final key = '${_storage.getString(LocalStorage.keyToken)}|$establishmentId';
    if (key == _cacheKey) return;
    _cacheKey = key;
    _assignments = null;
    _students.clear();
    _periods.clear();
  }

  /// GET qui renvoie `null` si le serveur refuse (403) ou ne trouve pas (404) la ressource.
  Future<dynamic> _tryGet(String path, {Map<String, dynamic>? query}) async {
    try {
      return await _api.get(path, query: query);
    } on ServerException {
      return null;
    }
  }

  Future<List<TeacherAssignment>> assignments() async {
    _refreshCache();
    final cached = _assignments;
    if (cached != null) return cached;

    final etab = establishmentId;
    final raw = ApiJson.list(await _api.get('/etablissements/$etab/mes-affectations'));
    // Les classes se listent par année scolaire (celle des affectations, normalement l'année courante).
    final years = {for (final a in raw) a['anneeScolaireId']}.whereType<String>();
    final classes = <Object?, String?>{
      for (final year in years)
        for (final c in ApiJson.list(await _tryGet('/etablissements/$etab/classes', query: {'anneeScolaireId': year})))
          c['id']: c['nom'] as String?,
    };
    final subjects = {
      for (final m in ApiJson.list(await _tryGet('/etablissements/$etab/matieres'))) m['id']: m,
    };

    final list = [
      for (final a in raw)
        TeacherAssignment(
          classId: a['classeId'] as String,
          className: classes[a['classeId']] ?? 'Classe',
          subjectId: a['matiereId'] as String,
          subject: subjects[a['matiereId']]?['nom'] as String? ?? 'Matière',
          coefficient: ApiJson.toDouble(subjects[a['matiereId']]?['coefficientDefaut']) ?? 1,
          schoolYearId: a['anneeScolaireId'] as String? ?? '',
        ),
    ]..sort((a, b) => a.className.compareTo(b.className));
    return _assignments = list;
  }

  /// Affectation correspondant à [classId], ou la première si [classId] est inconnu
  /// (ex. onglet « Notes » ouvert sans classe choisie).
  Future<TeacherAssignment> resolve(String classId) async {
    final list = await assignments();
    if (list.isEmpty) throw const ServerException('Aucune classe ne vous est affectée dans cet établissement.');
    return list.where((a) => a.classId == classId).firstOrNull ?? list.first;
  }

  /// Élèves inscrits dans la classe de [a] pour l'année courante
  /// (`GET /etablissements/{etab}/classes/{classe}/eleves`), triés par nom.
  Future<List<StudentRef>> students(TeacherAssignment a) async {
    _refreshCache();
    final cached = _students[a.classId];
    if (cached != null) return cached;

    final raw = ApiJson.list(await _api.get('/etablissements/$establishmentId/classes/${a.classId}/eleves'));
    final list = [
      for (final i in raw)
        StudentRef(
          id: (i['eleveId'] ?? ApiJson.map(i['eleve'])['id']) as String,
          name: ApiJson.studentName(i['eleve']),
          classId: a.classId,
        ),
    ];
    return _students[a.classId] = list;
  }

  /// Nombre d'élèves de chaque classe affectée (vide si le serveur refuse la liste des élèves).
  Future<Map<String, int>> studentCounts() async {
    final list = await assignments();
    if (list.isEmpty) return const {};
    try {
      final counts = <String, int>{};
      for (final a in list) {
        counts[a.classId] = (await students(a)).length;
      }
      return counts;
    } on ServerException {
      return const {};
    }
  }

  /// Période ouverte à la saisie pour l'année scolaire [schoolYearId].
  Future<PeriodRef> currentPeriod(String schoolYearId) async {
    _refreshCache();
    final cached = _periods[schoolYearId];
    if (cached != null) return cached;

    final raw = ApiJson.list(
      await _api.get('/etablissements/$establishmentId/annees-scolaires/$schoolYearId/periodes'),
    );
    if (raw.isEmpty) throw const ServerException('Aucune période n’est définie pour cette année scolaire.');
    final now = DateTime.now();
    bool covers(Map<String, dynamic> p) {
      final start = ApiJson.parseDate(p['dateDebut']);
      final end = ApiJson.parseDate(p['dateFin']);
      return start != null && end != null && !now.isBefore(start) && !now.isAfter(end.add(const Duration(days: 1)));
    }

    final open = raw.where((p) => p['saisieOuverte'] == true).toList();
    final p = open.where((p) => p['type'] == 'SEQUENCE').firstOrNull ??
        open.firstOrNull ??
        raw.where(covers).firstOrNull ??
        raw.first;
    return _periods[schoolYearId] = PeriodRef(
      id: p['id'] as String,
      label: periodLabel(p),
      isSequence: p['type'] == 'SEQUENCE',
    );
  }

  /// « Séquence 2 », « Trimestre 1 », « Année ».
  static String periodLabel(Map<String, dynamic> p) {
    final n = p['numero'];
    return switch (p['type']) {
      'SEQUENCE' => 'Séquence ${n ?? ''}'.trim(),
      'TRIMESTRE' => 'Trimestre ${n ?? ''}'.trim(),
      _ => 'Année',
    };
  }
}
