import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:college_bus_attendance/core/config/supabase_config.dart';
import 'package:college_bus_attendance/core/errors/app_exception.dart';
import 'package:college_bus_attendance/features/attendance/domain/attendance.dart';
import 'package:college_bus_attendance/features/students/data/student_repository.dart';

final scanRepositoryProvider = Provider((ref) => ScanRepository());

class ScanResult {
  final String status; // 'success' | 'duplicate' | 'error'
  final String message;
  final String? attendanceId;
  final DateTime? scannedAt;
  final Map<String, dynamic>? student;
  final String? sessionType;
  final String? busNumber;

  const ScanResult({
    required this.status,
    required this.message,
    this.attendanceId,
    this.scannedAt,
    this.student,
    this.sessionType,
    this.busNumber,
  });

  bool get isSuccess => status == 'success';
  bool get isDuplicate => status == 'duplicate';
}

class ScanRepository {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static final List<AttendanceRecord> _localRecords = [];
  static List<AttendanceRecord> get localRecords => List.unmodifiable(_localRecords);

  Future<ScanResult> recordAttendance({
    required String rollNumber,
    required String sessionId,
    required String idempotencyKey,
    String? busNumber,
    String? sessionType,
    String? conductorName,
    String? conductorId,
    String? busId,
  }) async {
    final cleanRoll = rollNumber.trim().toUpperCase();

    // 1. Try remote Edge Function if user has active Supabase session
    final session = _supabase?.auth.currentSession;
    if (session != null) {
      final url = Uri.parse('${SupabaseConfig.functionsUrl}/record-attendance');
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
            'apikey': SupabaseConfig.anonKey,
          },
          body: jsonEncode({
            'roll_number': cleanRoll,
            'session_id': sessionId,
            'idempotency_key': idempotencyKey,
          }),
        );

        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 201) {
          return ScanResult(
            status: 'success',
            message: body['message'] as String? ?? 'Attendance recorded',
            attendanceId: body['attendance_id'] as String?,
            scannedAt: body['scanned_at'] != null
                ? DateTime.parse(body['scanned_at'] as String)
                : DateTime.now(),
            student: body['student'] as Map<String, dynamic>?,
            sessionType: (body['session'] as Map?)?['type'] as String?,
            busNumber: body['bus_number'] as String?,
          );
        }

        if (response.statusCode == 200 && body['status'] == 'duplicate') {
          return ScanResult(
            status: 'duplicate',
            message: body['message'] as String? ?? 'Already marked',
            attendanceId: body['attendance_id'] as String?,
            scannedAt: body['scanned_at'] != null
                ? DateTime.parse(body['scanned_at'] as String)
                : null,
            student: body['student'] as Map<String, dynamic>?,
          );
        }

        if (response.statusCode == 404) {
          throw NotFoundException(body['message'] as String? ?? 'Student not found');
        }
      } catch (e) {
        if (e is NotFoundException) rethrow;
        // Edge Function unreachable or errored; proceed to resilient local lookup
      }
    }

    // 2. Resilient local student lookup and attendance registration
    final student = await StudentRepository().findByRollNumber(cleanRoll);
    if (student == null) {
      throw NotFoundException('Student not found for roll number: $cleanRoll');
    }

    // Check duplicate
    final isAlreadyScanned = _localRecords.any(
      (r) => r.sessionId == sessionId && r.scannedRollNumber == cleanRoll,
    );

    if (isAlreadyScanned) {
      return ScanResult(
        status: 'duplicate',
        message: 'Already marked for this session',
        student: {
          'name': student.name,
          'roll_number': student.rollNumber,
          'department': student.department,
          'academic_year': student.academicYear,
        },
      );
    }

    final activeBus = busNumber ?? 'BUS-01';
    final activeSessionType = sessionType ?? (sessionId.contains('evening') ? 'evening' : 'morning');

    final newRecord = AttendanceRecord(
      id: const Uuid().v4(),
      studentId: student.id,
      sessionId: sessionId,
      busId: busId ?? 'bus-$activeBus',
      conductorId: conductorId ?? 'conductor-current',
      scannedRollNumber: cleanRoll,
      scannedAt: DateTime.now(),
      studentName: student.name,
      studentDepartment: student.department,
      studentYear: student.academicYear,
      busNumber: activeBus,
      sessionType: activeSessionType,
    );
    _localRecords.insert(0, newRecord);

    // Sync to Supabase directly if client available
    try {
      if (_supabase != null) {
        await _supabase!.from('attendance_records').insert({
          'id': newRecord.id,
          'student_id': student.id,
          'session_id': sessionId,
          'bus_id': busId ?? 'bus-$activeBus',
          'conductor_id': conductorId ?? 'conductor-current',
          'scanned_roll_number': cleanRoll,
          'scanned_at': newRecord.scannedAt.toIso8601String(),
        }).timeout(const Duration(seconds: 2));
      }
    } catch (_) {}

    return ScanResult(
      status: 'success',
      message: 'Attendance recorded successfully',
      attendanceId: newRecord.id,
      scannedAt: newRecord.scannedAt,
      student: {
        'name': student.name,
        'roll_number': student.rollNumber,
        'department': student.department,
        'academic_year': student.academicYear,
      },
      sessionType: activeSessionType,
      busNumber: activeBus,
    );
  }

  // Get today's records for conductor's bus (for session summary screen)
  Future<List<AttendanceRecord>> getMyRecords(String sessionId) async {
    final List<AttendanceRecord> records = [];

    try {
      if (_supabase != null) {
        final data = await _supabase!
            .from('attendance_records')
            .select(
              'id, student_id, session_id, bus_id, conductor_id, '
              'scanned_roll_number, scanned_at, '
              'students(name, department, academic_year)',
            )
            .eq('session_id', sessionId)
            .order('scanned_at', ascending: false)
            .timeout(const Duration(seconds: 2));

        final remote = (data as List)
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        records.addAll(remote);
      }
    } catch (_) {}

    // Merge with local records
    for (final loc in _localRecords.where((r) => r.sessionId == sessionId)) {
      if (!records.any((r) => r.scannedRollNumber == loc.scannedRollNumber)) {
        records.add(loc);
      }
    }

    records.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return records;
  }
}
