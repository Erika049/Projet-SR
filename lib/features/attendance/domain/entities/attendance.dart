import 'package:equatable/equatable.dart';

enum AttendanceKind { absence, retard }

/// État du justificatif d'une absence/retard (table `justificatif_absence`).
enum JustificationStatus {
  aJustifier('À justifier'),
  enAttente('En attente de validation'),
  justifie('Justifié'),
  refuse('Refusé');

  const JustificationStatus(this.label);
  final String label;
}

/// Absence ou retard d'un enfant (CU-PAR-05).
class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.kind,
    required this.start,
    this.end,
    this.subject,
    this.minutesLate,
    this.status = JustificationStatus.aJustifier,
  });

  final String id;
  final AttendanceKind kind;
  final DateTime start;
  final DateTime? end;
  final String? subject;
  final int? minutesLate;
  final JustificationStatus status;

  /// « Absence · Mathématiques » / « Retard · 15 minutes »
  String get title => kind == AttendanceKind.absence
      ? 'Absence${subject == null ? '' : ' · $subject'}'
      : 'Retard · ${minutesLate ?? 0} minutes';

  AttendanceRecord withStatus(JustificationStatus s) => AttendanceRecord(
        id: id,
        kind: kind,
        start: start,
        end: end,
        subject: subject,
        minutesLate: minutesLate,
        status: s,
      );

  @override
  List<Object?> get props => [id, kind, start, end, subject, minutesLate, status];
}

class AttendanceSummary extends Equatable {
  const AttendanceSummary({required this.month, required this.records});

  final DateTime month;
  final List<AttendanceRecord> records;

  int get absences => records.where((r) => r.kind == AttendanceKind.absence).length;
  int get lates => records.where((r) => r.kind == AttendanceKind.retard).length;
  int get toJustify => records.where((r) => r.status == JustificationStatus.aJustifier).length;

  @override
  List<Object?> get props => [month, records];
}

// ───────────────────────────── Enseignant ─────────────────────────────

enum RollCallStatus { present, absent, retard }

class RollCallEntry extends Equatable {
  const RollCallEntry({required this.studentId, required this.studentName, this.status = RollCallStatus.present});

  final String studentId;
  final String studentName;
  final RollCallStatus status;

  RollCallEntry withStatus(RollCallStatus s) =>
      RollCallEntry(studentId: studentId, studentName: studentName, status: s);

  @override
  List<Object?> get props => [studentId, studentName, status];
}

/// Séance d'appel d'une classe (tables `appel` + `presence_eleve`, CU-ENS-03).
class RollCall extends Equatable {
  const RollCall({
    required this.id,
    required this.classId,
    required this.className,
    required this.subject,
    required this.start,
    required this.end,
    required this.entries,
  });

  final String id;
  final String classId;
  final String className;
  final String subject;
  final DateTime start;
  final DateTime end;
  final List<RollCallEntry> entries;

  int count(RollCallStatus s) => entries.where((e) => e.status == s).length;

  RollCall withEntries(List<RollCallEntry> list) => RollCall(
        id: id,
        classId: classId,
        className: className,
        subject: subject,
        start: start,
        end: end,
        entries: list,
      );

  @override
  List<Object?> get props => [id, classId, className, subject, start, end, entries];
}

enum StaffStatus {
  present('Présent'),
  retard('Retard'),
  absent('Absent');

  const StaffStatus(this.label);
  final String label;
}

class StaffAttendanceDay extends Equatable {
  const StaffAttendanceDay({required this.date, required this.status, this.minutesLate});

  final DateTime date;
  final StaffStatus status;
  final int? minutesLate;

  @override
  List<Object?> get props => [date, status, minutesLate];
}

/// « Ma présence » de l'enseignant (CU-ENS-08).
class MyAttendance extends Equatable {
  const MyAttendance({required this.today, this.firstCourse, this.todayStatus, this.history = const []});

  final DateTime today;
  final DateTime? firstCourse;
  final StaffStatus? todayStatus;
  final List<StaffAttendanceDay> history;

  @override
  List<Object?> get props => [today, firstCourse, todayStatus, history];
}
