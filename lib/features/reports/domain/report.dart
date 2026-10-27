class AttendanceSummaryReport {
  final String date;
  final String sessionType;
  final int totalScans;
  final Map<String, int> busBreakdown;
  final Map<String, int> departmentBreakdown;
  final Map<String, int> yearBreakdown;

  const AttendanceSummaryReport({
    required this.date,
    required this.sessionType,
    required this.totalScans,
    required this.busBreakdown,
    required this.departmentBreakdown,
    required this.yearBreakdown,
  });
}

class ReportFilter {
  final DateTime startDate;
  final DateTime endDate;
  final String sessionType; // 'all', 'morning', 'evening'
  final String? busId;
  final String? department;

  const ReportFilter({
    required this.startDate,
    required this.endDate,
    this.sessionType = 'all',
    this.busId,
    this.department,
  });

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? sessionType,
    String? busId,
    String? department,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sessionType: sessionType ?? this.sessionType,
      busId: busId ?? this.busId,
      department: department ?? this.department,
    );
  }
}
