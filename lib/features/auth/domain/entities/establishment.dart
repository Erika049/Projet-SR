import 'package:equatable/equatable.dart';

/// Établissement auquel un enseignant est rattaché (écran « Choisir un établissement »).
class Establishment extends Equatable {
  const Establishment({required this.id, required this.nom, this.classesCount = 0, this.matiere});

  final String id;
  final String nom;
  final int classesCount;
  final String? matiere;

  @override
  List<Object?> get props => [id, nom, classesCount, matiere];
}
