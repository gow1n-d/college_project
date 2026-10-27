import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:college_bus_attendance/features/barcode_scanner/data/scan_repository.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';

class SessionSummaryPage extends ConsumerWidget {
  final String sessionId;
  const SessionSummaryPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(_sessionRecordsProvider(sessionId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_sessionRecordsProvider(sessionId)),
          ),
        ],
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          final count = records.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCol('Scanned', '$count', Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('$count students scanned',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...records.map((r) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.check, color: Colors.green, size: 18),
                    ),
                    title: Text(r.studentName ?? r.scannedRollNumber),
                    subtitle: Text(
                        '${r.scannedRollNumber} · ${r.studentDepartment ?? ''}'),
                    trailing: Text(
                      AppDateUtils.formatTime(r.scannedAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

final _sessionRecordsProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) {
  return ref.read(scanRepositoryProvider).getMyRecords(sessionId);
});
