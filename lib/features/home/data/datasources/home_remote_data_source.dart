import '../../../../core/network/mock_delay.dart';
import '../../domain/entities/parent_overview.dart';

abstract interface class HomeRemoteDataSource {
  Future<ParentOverview> getParentOverview();
}

/// Accueil parent de démonstration (maquette « Bonjour, Mme Etame »).
class HomeMockDataSource implements HomeRemoteDataSource {
  @override
  Future<ParentOverview> getParentOverview() async {
    await mockDelay();
    return const ParentOverview(
      summaries: [
        ChildSummary(childId: 'eleve-amina', average: 14.6, absencesToJustify: 1),
        ChildSummary(childId: 'eleve-junior', gradesPublished: false),
      ],
      highlights: [
        Highlight(kind: HighlightKind.absence, childId: 'eleve-amina', text: 'Absence · Amina · Aujourd’hui, 8 h'),
        Highlight(kind: HighlightKind.note, childId: 'eleve-amina', text: 'Note publiée · Amina · Maths : 16/20'),
        Highlight(kind: HighlightKind.paiement, text: 'Paiement · 45 000 FCFA avant le 30/11'),
      ],
    );
  }
}
