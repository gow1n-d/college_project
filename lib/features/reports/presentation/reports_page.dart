import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:college_bus_attendance/features/reports/data/report_repository.dart';
import 'package:college_bus_attendance/features/reports/domain/report.dart';
import 'package:college_bus_attendance/features/buses/data/bus_repository.dart';
import 'package:college_bus_attendance/features/attendance/domain/attendance.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';

final _reportFilterProvider = StateProvider<ReportFilter>((ref) {
  final now = DateTime.now();
  return ReportFilter(
    startDate: now.subtract(const Duration(days: 7)),
    endDate: now,
  );
});

final _filteredRecordsProvider = FutureProvider.autoDispose((ref) {
  final filter = ref.watch(_reportFilterProvider);
  return ref.read(reportRepositoryProvider).fetchRecords(filter);
});

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String _tableSearch = '';

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(_reportFilterProvider);
    final recordsAsync = ref.watch(_filteredRecordsProvider);
    final busesAsync = ref.watch(busRepositoryProvider).getAll();

    final isMobile = MediaQuery.of(context).size.width < 700;

    void exportRecords(List<AttendanceRecord> records) {
      if (records.isEmpty) return;
      final csv = ref.read(reportRepositoryProvider).generateCsv(records);
      Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV copied to clipboard (${records.length} records)'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isMobile ? 'Reports' : 'Attendance Reports & Analytics'),
        actions: [
          recordsAsync.when(
            data: (records) {
              if (isMobile) {
                return IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Export CSV',
                  onPressed: records.isEmpty ? null : () => exportRecords(records),
                );
              }
              return FilledButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export CSV'),
                onPressed: records.isEmpty ? null : () => exportRecords(records),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Filter Toolbar Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Date range button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      '${AppDateUtils.formatDate(filter.startDate)} - ${AppDateUtils.formatDate(filter.endDate)}',
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                        initialDateRange: DateTimeRange(
                          start: filter.startDate,
                          end: filter.endDate,
                        ),
                      );
                      if (picked != null) {
                        ref.read(_reportFilterProvider.notifier).state = filter.copyWith(
                          startDate: picked.start,
                          endDate: picked.end,
                        );
                      }
                    },
                  ),

                  // Session Type SegmentedButton
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('All')),
                      ButtonSegment(value: 'morning', label: Text('Morning')),
                      ButtonSegment(value: 'evening', label: Text('Evening')),
                    ],
                    selected: {filter.sessionType},
                    onSelectionChanged: (val) {
                      ref.read(_reportFilterProvider.notifier).state =
                          filter.copyWith(sessionType: val.first);
                    },
                  ),

                  // Bus filter dropdown
                  FutureBuilder(
                    future: busesAsync,
                    builder: (context, snapshot) {
                      final buses = snapshot.data ?? [];
                      return DropdownButton<String?>(
                        value: filter.busId,
                        hint: const Text('All Buses'),
                        underline: const SizedBox(),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Buses')),
                          ...buses.map((b) => DropdownMenuItem(
                                value: b.id,
                                child: Text('Bus ${b.busNumber}'),
                              )),
                        ],
                        onChanged: (busId) {
                          ref.read(_reportFilterProvider.notifier).state =
                              filter.copyWith(busId: busId);
                        },
                      );
                    },
                  ),

                  // Search in current table
                  SizedBox(
                    width: 220,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search results…',
                        prefixIcon: Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (v) => setState(() => _tableSearch = v),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Report',
                    onPressed: () => ref.invalidate(_filteredRecordsProvider),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error generating report: $e')),
              data: (records) {
                if (records.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No attendance records found for this period/filter'),
                      ],
                    ),
                  );
                }

                // Compute KPI aggregations
                final total = records.length;
                final morningCount = records.where((r) => r.sessionType == 'morning').length;
                final eveningCount = records.where((r) => r.sessionType == 'evening').length;
                final uniqueBuses = records.map((r) => r.busNumber).where((b) => b != null).toSet().length;

                // Department breakdown
                final deptMap = <String, int>{};
                for (final r in records) {
                  final dept = r.studentDepartment ?? 'Unknown';
                  deptMap[dept] = (deptMap[dept] ?? 0) + 1;
                }

                final filteredRecords = _tableSearch.isEmpty
                    ? records
                    : records.where((r) {
                        final q = _tableSearch.toLowerCase();
                        return (r.studentName?.toLowerCase().contains(q) ?? false) ||
                            r.scannedRollNumber.toLowerCase().contains(q) ||
                            (r.busNumber?.toLowerCase().contains(q) ?? false) ||
                            (r.studentDepartment?.toLowerCase().contains(q) ?? false);
                      }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI Row
                      Row(
                        children: [
                          _buildKpiCard('Total Scans', '$total', Icons.verified_user, Colors.blue),
                          const SizedBox(width: 12),
                          _buildKpiCard('Morning', '$morningCount', Icons.wb_sunny, Colors.orange),
                          const SizedBox(width: 12),
                          _buildKpiCard('Evening', '$eveningCount', Icons.nightlight_round, Colors.indigo),
                          const SizedBox(width: 12),
                          _buildKpiCard('Active Buses', '$uniqueBuses', Icons.directions_bus, Colors.teal),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Department Breakdown Chip Row
                      const Text(
                        'Department Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: deptMap.entries.map((e) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(
                                '${e.value}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            label: Text(e.key),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Detailed Table
                      Text(
                        'Detailed Attendance Log (${filteredRecords.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Scanned At')),
                            DataColumn(label: Text('Roll No.')),
                            DataColumn(label: Text('Student Name')),
                            DataColumn(label: Text('Department')),
                            DataColumn(label: Text('Year')),
                            DataColumn(label: Text('Bus')),
                            DataColumn(label: Text('Trip')),
                            DataColumn(label: Text('Conductor')),
                          ],
                          rows: filteredRecords.map((r) {
                            return DataRow(cells: [
                              DataCell(Text(AppDateUtils.formatFull(r.scannedAt))),
                              DataCell(Text(r.scannedRollNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(r.studentName ?? '—')),
                              DataCell(Text(r.studentDepartment ?? '—')),
                              DataCell(Text(r.studentYear ?? '—')),
                              DataCell(Text(r.busNumber ?? '—')),
                              DataCell(Chip(
                                label: Text(
                                  (r.sessionType ?? '—').toUpperCase(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                visualDensity: VisualDensity.compact,
                              )),
                              DataCell(Text(r.conductorName ?? '—')),
                            ]);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                radius: 20,
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
