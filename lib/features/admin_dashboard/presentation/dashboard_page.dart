import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _selectedDate = AppDateUtils.todayServiceDate;
  RealtimeChannel? _channel;
  Timer? _liveTimer;
  List<AttendanceRecord> _records = [];
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeRealtime();
    // Live update ticker every 2 seconds so admin sees scans directly without refreshing
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    try {
      if (_channel != null) {
        Supabase.instance.client.removeChannel(_channel!);
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final results = await Future.wait([
        repo.getRecords(date: _selectedDate),
        repo.getDashboardStats(_selectedDate),
      ]);
      if (mounted) {
        setState(() {
          _records = results[0] as List<AttendanceRecord>;
          _stats = results[1] as Map<String, int>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    try {
      final supabase = Supabase.instance.client;
      _channel = supabase.channel('attendance_realtime');
      _channel
          ?.onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'attendance_records',
            callback: (payload) {
              // Refresh immediately on new record
              _loadData(silent: true);
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void _exportCsv() {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance records to export for this date')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Roll Number,Student Name,Department,Academic Year,Bus Number,Session,Scanned At');
    for (final r in _records) {
      buffer.writeln(
        '"${r.scannedRollNumber}",'
        '"${r.studentName ?? ''}",'
        '"${r.studentDepartment ?? ''}",'
        '"${r.studentYear ?? ''}",'
        '"${r.busNumber ?? ''}",'
        '"${r.sessionType ?? ''}",'
        '"${r.scannedAt.toIso8601String()}"',
      );
    }

    final csvData = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvData));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Exported ${_records.length} records to CSV (Copied to Clipboard)'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked.toIso8601String().split('T')[0]);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dashboard'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3.5, backgroundColor: Colors.green),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Export CSV',
              onPressed: _exportCsv,
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Pick Date: ${AppDateUtils.formatDateStr(_selectedDate)}',
              onPressed: () => _pickDate(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _loadData(),
            ),
            const SizedBox(width: 4),
          ] else ...[
            FilledButton.tonalIcon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export CSV'),
              onPressed: _exportCsv,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(AppDateUtils.formatDateStr(_selectedDate)),
              onPressed: () => _pickDate(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Manual Refresh',
              onPressed: () => _loadData(),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // KPI cards
                _KpiGrid(stats: _stats),
                const SizedBox(height: 24),

                // Attendance table
                Text('Live Attendance',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _AttendanceTable(records: _records),
              ],
            ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final Map<String, int> stats;
  const _KpiGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiData('Total Students', '${stats['total_students'] ?? 0}',
          Icons.people_outline, Colors.blue),
      _KpiData('Active Buses', '${stats['total_buses'] ?? 0}',
          Icons.directions_bus_outlined, Colors.teal),
      _KpiData('Conductors', '${stats['total_conductors'] ?? 0}',
          Icons.person_outline, Colors.indigo),
      _KpiData('Morning Scanned', '${stats['morning_count'] ?? 0}',
          Icons.wb_sunny_outlined, Colors.orange),
      _KpiData('Evening Scanned', '${stats['evening_count'] ?? 0}',
          Icons.nights_stay_outlined, Colors.purple),
      _KpiData('Not Yet Scanned', '${stats['not_scanned'] ?? 0}',
          Icons.hourglass_empty, Colors.red),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 135,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _KpiCard(data: cards[i]),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, color: data.color, size: 22),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: data.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTable extends StatefulWidget {
  final List<AttendanceRecord> records;
  const _AttendanceTable({required this.records});

  @override
  State<_AttendanceTable> createState() => _AttendanceTableState();
}

class _AttendanceTableState extends State<_AttendanceTable> {
  String _search = '';
  String? _sessionFilter;

  List<AttendanceRecord> get _filtered {
    return widget.records.where((r) {
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          (r.scannedRollNumber.toLowerCase().contains(q)) ||
          (r.studentName?.toLowerCase().contains(q) ?? false);
      final matchSession =
          _sessionFilter == null || r.sessionType == _sessionFilter;
      return matchSearch && matchSession;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by roll / name…',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _sessionFilter,
                  hint: const Text('All sessions'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'morning', child: Text('Morning')),
                    DropdownMenuItem(value: 'evening', child: Text('Evening')),
                  ],
                  onChanged: (v) => setState(() => _sessionFilter = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No records found')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.surfaceContainerHighest),
                columns: const [
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Roll No.')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Dept')),
                  DataColumn(label: Text('Year')),
                  DataColumn(label: Text('Bus')),
                  DataColumn(label: Text('Conductor')),
                  DataColumn(label: Text('Session')),
                ],
                rows: filtered
                    .map((r) => DataRow(cells: [
                          DataCell(Text(AppDateUtils.formatTime(r.scannedAt))),
                          DataCell(Text(r.scannedRollNumber)),
                          DataCell(Text(r.studentName ?? '--')),
                          DataCell(Text(r.studentDepartment ?? '--')),
                          DataCell(Text(r.studentYear ?? '--')),
                          DataCell(Text(r.busNumber ?? '--')),
                          DataCell(Text(r.conductorName ?? '--')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: r.sessionType == 'morning'
                                    ? Colors.orange.withValues(alpha: 0.15)
                                    : Colors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                r.sessionType?.toUpperCase() ?? '--',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: r.sessionType == 'morning'
                                      ? Colors.orange.shade800
                                      : Colors.purple.shade800,
                                ),
                              ),
                            ),
                          ),
                        ]))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
