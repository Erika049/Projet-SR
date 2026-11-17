import 'package:equatable/equatable.dart';

/// Créneau de cours de l'enseignant.
class Course extends Equatable {
  const Course({
    required this.id,
    required this.classId,
    required this.className,
    required this.subject,
    required this.start,
    required this.end,
    required this.room,
    required this.studentCount,
  });

  final String id;
  final String classId;
  final String className;
  final String subject;
  final DateTime start;
  final DateTime end;
  final String room;
  final int studentCount;

  bool isOngoing(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  @override
  List<Object?> get props => [id, classId, className, subject, start, end, room, studentCount];
}

/// Classe tenue par l'enseignant (« Mes classes »).
class TeacherClass extends Equatable {
  const TeacherClass({required this.id, required this.name, required this.studentCount, this.nextCourse});

  final String id;
  final String name;
  final int studentCount;
  final Course? nextCourse;

  @override
  List<Object?> get props => [id, name, studentCount, nextCourse];
}
