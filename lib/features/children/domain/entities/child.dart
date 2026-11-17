import 'package:equatable/equatable.dart';

/// Droits d'un parent/tuteur sur un enfant (table `parent_eleve`).
class ChildRights extends Equatable {
  const ChildRights({this.canView = true, this.canPay = false, this.canJustify = false});

  final bool canView;
  final bool canPay;
  final bool canJustify;

  List<String> get labels => [if (canView) 'Voir', if (canPay) 'Payer', if (canJustify) 'Justifier'];

  @override
  List<Object?> get props => [canView, canPay, canJustify];
}

/// Enfant rattaché au compte du parent (élève + inscription courante).
class Child extends Equatable {
  const Child({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.classe,
    required this.etablissement,
    required this.anneeScolaire,
    this.matricule,
    this.rights = const ChildRights(),
  });

  final String id;
  final String prenom;
  final String nom;
  final String classe;
  final String etablissement;
  final String anneeScolaire;
  final String? matricule;
  final ChildRights rights;

  String get fullName => '$prenom $nom';

  /// « Amina Etame · 3e A »
  String get label => '$fullName · $classe';

  @override
  List<Object?> get props => [id, prenom, nom, classe, etablissement, anneeScolaire, matricule, rights];
}

/// Demande de liaison en attente de validation par le secrétariat.
class LinkRequest extends Equatable {
  const LinkRequest({required this.id, required this.childName, required this.classe});

  final String id;
  final String childName;
  final String classe;

  @override
  List<Object?> get props => [id, childName, classe];
}
