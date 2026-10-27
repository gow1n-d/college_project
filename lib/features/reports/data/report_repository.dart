import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:college_bus_attendance/features/attendance/domain/attendance.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';
import '../domain/report.dart';

final reportRepositoryProvider = Provider((ref) => ReportRepository());

class ReportRepository {
  final _db = Supabase.instance.client;

  Future<List<AttendanceRecord>> fetchRecords(ReportFilter filter) async {
    var query = _db
        .from('attendance_records')
        .select(
          'id, student_id, session_id, bus_id, conductor_id, '
          'scanned_roll_number, scanned_at, '
          'students(name, department, academic_year), '
          'buses(bus_number), '
          'profiles(display_name), '
          'attendance_sessions!inner(service_date, session_type)',
        );

    // Apply date range filter on joined session service_date
    final startDateIso =
        '${filter.startDate.year}-${filter.startDate.month.toString().padLeft(2, '0')}-${filter.startDate.day.toString().padLeft(2, '0')}';
    final endDateIso =
        '${filter.endDate.year}-${filter.endDate.month.toString().padLeft(2, '0')}-${filter.endDate.day.toString().padLeft(2, '0')}';

    query = query
        .gte('attendance_sessions.service_date', startDateIso)
        .lte('attendance_sessions.service_date', endDateIso) as dynamic;

    if (filter.sessionType != 'all') {
      query = query.eq('attendance_sessions.session_type', filter.sessionType) as dynamic;
    }
    if (filter.busId != null && filter.busId!.isNotEmpty) {
      query = query.eq('bus_id', filter.busId!) as dynamic;
    }

    final data = await (query as dynamic).order('scanned_at', ascending: false);
    final records = (data as List)
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    if (filter.department != null && filter.department!.isNotEmpty) {
      return records.where((r) => r.studentDepartment == filter.department).toList();
    }
    return records;
  }

  String generateCsv(List<AttendanceRecord> records) {
    final rows = <List<dynamic>>[
      [
        'Scanned At',
        'Roll Number',
        'Student Name',
        'Department',
        'Academic Year',
        'Bus Number',
        'Session Type',
        'Conductor',
      ],
      ...records.map((r) => [
            AppDateUtils.formatFull(r.scannedAt),
            r.scannedRollNumber,
            r.studentName ?? '',
            r.studentDepartment ?? '',
            r.studentYear ?? '',
            r.busNumber ?? '',
            r.sessionType ?? '',
            r.conductorName ?? '',
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }
}
