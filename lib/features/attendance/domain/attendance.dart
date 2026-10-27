class AttendanceSession {
  final String id;
  final String sessionType; // 'morning' | 'evening'
  final String serviceDate; // yyyy-MM-dd
  final String status; // 'scheduled' | 'open' | 'closed'
  final DateTime? opensAt;
  final DateTime? closesAt;
  final DateTime createdAt;

  const AttendanceSession({
    required this.id,
    required this.sessionType,
    required this.serviceDate,
    required this.status,
    this.opensAt,
    this.closesAt,
    required this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get isScheduled => status == 'scheduled';
  bool get isMorning => sessionType == 'morning';

  factory AttendanceSession.fromJson(Map<String, dynamic> j) => AttendanceSession(
        id: j['id'] as String,
        sessionType: j['session_type'] as String,
        serviceDate: j['service_date'] as String,
        status: j['status'] as String,
        opensAt: j['opens_at'] != null ? DateTime.parse(j['opens_at'] as String) : null,
        closesAt: j['closes_at'] != null ? DateTime.parse(j['closes_at'] as String) : null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String sessionId;
  final String busId;
  final String conductorId;
  final String scannedRollNumber;
  final DateTime scannedAt;
  // Joined fields (from dashboard queries)
  final String? studentName;
  final String? studentDepartment;
  final String? studentYear;
  final String? busNumber;
  final String? conductorName;
  final String? sessionType;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.busId,
    required this.conductorId,
    required this.scannedRollNumber,
    required this.scannedAt,
    this.studentName,
    this.studentDepartment,
    this.studentYear,
    this.busNumber,
    this.conductorName,
    this.sessionType,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    final student = j['students'] as Map<String, dynamic>?;
    final bus = j['buses'] as Map<String, dynamic>?;
    final conductor = j['profiles'] as Map<String, dynamic>?;
    final session = j['attendance_sessions'] as Map<String, dynamic>?;
    return AttendanceRecord(
      id: j['id'] as String,
      studentId: j['student_id'] as String,
      sessionId: j['session_id'] as String,
      busId: j['bus_id'] as String,
      conductorId: j['conductor_id'] as String,
      scannedRollNumber: j['scanned_roll_number'] as String,
      scannedAt: DateTime.parse(j['scanned_at'] as String),
      studentName: student?['name'] as String?,
      studentDepartment: student?['department'] as String?,
      studentYear: student?['academic_year'] as String?,
      busNumber: bus?['bus_number'] as String?,
      conductorName: conductor?['display_name'] as String?,
      sessionType: session?['session_type'] as String?,
    );
  }
}
