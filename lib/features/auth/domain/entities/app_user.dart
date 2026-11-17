import 'package:equatable/equatable.dart';

/// Rôles ayant accès à l'application mobile.
/// (Direction, secrétariat, économat… utilisent l'application web.)
enum UserRole { parent, enseignant }

/// Utilisateur connecté (table `utilisateur` du dictionnaire de données).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.role,
    this.civilite,
    this.telephone,
    this.email,
    this.langue = 'fr',
    this.specialite,
  });

  final String id;
  final String nom;
  final String prenom;
  final UserRole role;

  /// « Mme », « M. » — utilisé pour l'accueil (« Bonjour, Mme Etame »).
  final String? civilite;
  final String? telephone;
  final String? email;
  final String langue;

  /// Matière principale d'un enseignant.
  final String? specialite;

  String get fullName => '$prenom $nom';
  String get greetingName => civilite == null ? prenom : '$civilite $nom';
  bool get isParent => role == UserRole.parent;

  @override
  List<Object?> get props => [id, nom, prenom, role, civilite, telephone, email, langue, specialite];
}
