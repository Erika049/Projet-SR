import '../../../../core/network/mock_delay.dart';
import '../../domain/entities/attendance.dart';

abstract interface class AttendanceRemoteDataSource {
  Future<AttendanceSummary> getChildAttendance(String childId, DateTime month);
  Future<void> justifyAbsence(String recordId, String reason, String? attachmentPath);
  Future<void> reportError(String childId, String message);
  Future<RollCall> getRollCall(String classId);
  Future<void> saveRollCall(RollCall rollCall);
  Future<MyAttendance> getMyAttendance();
  Future<MyAttendance> signalMyPresence();
  Future<MyAttendance> signalMyAbsence(String reason);
}

/// Données de démonstration (novembre 2026, maquettes).
class AttendanceMockDataSource implements AttendanceRemoteDataSource {
  final Map<String, List<AttendanceRecord>> _records = {
    'eleve-amina': [
      AttendanceRecord(
        id: 'abs-1',
        kind: AttendanceKind.absence,
        start: DateTime(2026, 11, 9, 8),
        end: DateTime(2026, 11, 9, 9),
        subject: 'Mathématiques',
      ),
      AttendanceRecord(
        id: 'ret-1',
        kind: AttendanceKind.retard,
        start: DateTime(2026, 11, 5, 8),
        minutesLate: 15,
        status: JustificationStatus.justifie,
      ),
      AttendanceRecord(
        id: 'abs-2',
        kind: AttendanceKind.absence,
        start: DateTime(2026, 11, 2, 10, 15),
        end: DateTime(2026, 11, 2, 11, 15),
        subject: 'Anglais',
        status: JustificationStatus.enAttente,
      ),
    ],
  };

  static const _students = {
    '3eA': ['Amina Etame', 'Boris Fotso', 'Carine Mbarga', 'David Njoya', 'Esther Ngo', 'Franck Tchoua'],
    '4eB': ['Gaëlle Abena', 'Hervé Nana', 'Irène Mballa', 'Jules Onana'],
    '2ndeC': ['Kevin Ateba', 'Laure Bella', 'Marc Essomba', 'Nadia Fouda'],
  };
  static const _classNames = {'3eA': '3e A', '4eB': '4e B', '2ndeC': '2nde C'};

  final Map<String, RollCall> _rollCalls = {};

  MyAttendance _me = MyAttendance(
    today: DateTime(2026, 11, 9),
    firstCourse: DateTime(2026, 11, 9, 8),
    history: [
      StaffAttendanceDay(date: DateTime(2026, 11, 6), status: StaffStatus.present),
      StaffAttendanceDay(date: DateTime(2026, 11, 5), status: StaffStatus.retard, minutesLate: 10),
      StaffAttendanceDay(date: DateTime(2026, 11, 4), status: StaffStatus.present),
    ],
  );

  @override
  Future<AttendanceSummary> getChildAttendance(String childId, DateTime month) async {
    await mockDelay();
    final records =
        (_records[childId] ?? const [])
            .where((r) => r.start.year == month.year && r.start.month == month.month)
            .toList()
          ..sort((a, b) => b.start.compareTo(a.start));
    return AttendanceSummary(month: month, records: records);
  }

  @override
  Future<void> justifyAbsence(String recordId, String reason, String? attachmentPath) async {
    await mockDelay();
    for (final list in _records.values) {
      final i = list.indexWhere((r) => r.id == recordId);
      if (i >= 0) list[i] = list[i].withStatus(JustificationStatus.enAttente);
    }
  }

  @override
  Future<void> reportError(String childId, String message) => mockDelay();

  @override
  Future<RollCall> getRollCall(String classId) async {
    await mockDelay();
    return _rollCalls[classId] ??
        RollCall(
          id: 'appel-$classId-20261109',
          classId: classId,
          className: _classNames[classId] ?? classId,
          subject: 'Mathématiques',
          start: DateTime(2026, 11, 9, 8),
          end: DateTime(2026, 11, 9, 9),
          entries: [
            for (final (i, name) in (_students[classId] ?? const []).indexed)
              RollCallEntry(studentId: '$classId-$i', studentName: name),
          ],
        );
  }

  @override
  Future<void> saveRollCall(RollCall rollCall) async {
    await mockDelay();
    _rollCalls[rollCall.classId] = rollCall;
  }

  @override
  Future<MyAttendance> getMyAttendance() async {
    await mockDelay();
    return _me;
  }

  @override
  Future<MyAttendance> signalMyPresence() async {
    await mockDelay();
    return _me = MyAttendance(
      today: _me.today,
      firstCourse: _me.firstCourse,
      todayStatus: StaffStatus.present,
      history: _me.history,
    );
  }

  @override
  Future<MyAttendance> signalMyAbsence(String reason) async {
    await mockDelay();
    return _me = MyAttendance(
      today: _me.today,
      firstCourse: _me.firstCourse,
      todayStatus: StaffStatus.absent,
      history: _me.history,
    );
  }
}
