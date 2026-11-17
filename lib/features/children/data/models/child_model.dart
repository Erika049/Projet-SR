import '../../domain/entities/child.dart';

class ChildModel extends Child {
  const ChildModel({
    required super.id,
    required super.prenom,
    required super.nom,
    required super.classe,
    required super.etablissement,
    required super.anneeScolaire,
    super.matricule,
    super.rights,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
    id: json['eleve_id'] as String,
    prenom: json['prenom'] as String,
    nom: json['nom'] as String,
    classe: json['classe'] as String,
    etablissement: json['etablissement'] as String,
    anneeScolaire: json['annee_scolaire'] as String,
    matricule: json['matricule'] as String?,
    rights: ChildRights(
      canView: json['peut_consulter'] as bool? ?? true,
      canPay: json['peut_payer'] as bool? ?? false,
      canJustify: json['peut_justifier'] as bool? ?? false,
    ),
  );
}

class LinkRequestModel extends LinkRequest {
  const LinkRequestModel({required super.id, required super.childName, required super.classe});

  factory LinkRequestModel.fromJson(Map<String, dynamic> json) =>
      LinkRequestModel(id: json['id'] as String, childName: json['eleve'] as String, classe: json['classe'] as String);
}
