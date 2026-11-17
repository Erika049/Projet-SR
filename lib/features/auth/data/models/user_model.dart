import '../../domain/entities/app_user.dart';
import '../../domain/entities/establishment.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.role,
    super.civilite,
    super.telephone,
    super.email,
    super.langue,
    super.specialite,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    nom: json['nom'] as String,
    prenom: json['prenom'] as String,
    role: UserRole.values.byName(json['role'] as String),
    civilite: json['civilite'] as String?,
    telephone: json['telephone'] as String?,
    email: json['email'] as String?,
    langue: json['langue'] as String? ?? 'fr',
    specialite: json['specialite'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'role': role.name,
    'civilite': civilite,
    'telephone': telephone,
    'email': email,
    'langue': langue,
    'specialite': specialite,
  };
}

class EstablishmentModel extends Establishment {
  const EstablishmentModel({required super.id, required super.nom, super.classesCount, super.matiere});

  factory EstablishmentModel.fromJson(Map<String, dynamic> json) => EstablishmentModel(
    id: json['id'] as String,
    nom: json['nom'] as String,
    classesCount: json['nb_classes'] as int? ?? 0,
    matiere: json['matiere'] as String?,
  );

  factory EstablishmentModel.fromEntity(Establishment e) =>
      EstablishmentModel(id: e.id, nom: e.nom, classesCount: e.classesCount, matiere: e.matiere);

  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'nb_classes': classesCount, 'matiere': matiere};
}

/// Réponse d'authentification : jeton + utilisateur.
typedef AuthSession = ({String token, UserModel user});
