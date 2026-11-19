import 'package:intl/intl.dart';

import '../errors/exceptions.dart';

/// Petits utilitaires de lecture des réponses JSON du backend.
abstract final class ApiJson {
  /// Date au format attendu par l'API : `2026-11-18`.
  static String date(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime? parseDate(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static double? toDouble(Object? v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  static int toInt(Object? v) => toDouble(v)?.round() ?? 0;

  static Map<String, dynamic> map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<Map<String, dynamic>> list(Object? v) =>
      v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];

  /// « Prénom Nom » d'un `EleveView`.
  static String studentName(Object? eleve) {
    final e = map(eleve);
    return [e['prenom'], e['nom']].whereType<String>().where((s) => s.isNotEmpty).join(' ');
  }
}

/// Fonction de l'application sans équivalent dans l'API actuelle.
/// Le message s'affiche tel quel à l'écran.
Never notAvailableOnServer(String feature) =>
    throw ServerException('$feature : pas encore disponible sur le serveur SchoolConnect.');
