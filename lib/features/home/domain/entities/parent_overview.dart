import 'package:equatable/equatable.dart';

/// Résumé d'un enfant sur l'accueil parent (vue consolidée, CU-PAR-03).
class ChildSummary extends Equatable {
  const ChildSummary({
    required this.childId,
    this.average,
    this.absencesToJustify = 0,
    this.gradesPublished = true,
    this.periodLabel = 'Séquence 1',
  });

  final String childId;
  final double? average;
  final int absencesToJustify;
  final bool gradesPublished;
  final String periodLabel;

  @override
  List<Object?> get props => [childId, average, absencesToJustify, gradesPublished, periodLabel];
}

enum HighlightKind { absence, note, paiement }

/// Ligne « À ne pas manquer ».
class Highlight extends Equatable {
  const Highlight({required this.kind, required this.text, this.childId});

  final HighlightKind kind;
  final String text;
  final String? childId;

  @override
  List<Object?> get props => [kind, text, childId];
}

class ParentOverview extends Equatable {
  const ParentOverview({required this.summaries, required this.highlights});

  final List<ChildSummary> summaries;
  final List<Highlight> highlights;

  ChildSummary? summaryOf(String childId) => summaries.where((s) => s.childId == childId).firstOrNull;

  @override
  List<Object?> get props => [summaries, highlights];
}
