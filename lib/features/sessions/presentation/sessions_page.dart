import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:college_bus_attendance/features/attendance/data/attendance_repository.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';

final _sessionsListProvider = FutureProvider.autoDispose((ref) {
  return ref.read(attendanceRepositoryProvider).getSessions();
});

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(_sessionsListProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMobile ? 'Sessions' : 'Attendance Sessions'),
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.add_alarm),
              tooltip: 'Create Session',
              onPressed: () => _showCreateSessionDialog(context),
            )
          else ...[
            FilledButton.icon(
              icon: const Icon(Icons.add_alarm, size: 18),
              label: const Text('Create Session'),
              onPressed: () => _showCreateSessionDialog(context),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ...['all', 'open', 'scheduled', 'closed'].map((status) {
                    final isSelected = _statusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(status.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _statusFilter = status);
                        },
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Sessions',
                    onPressed: () => ref.invalidate(_sessionsListProvider),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading sessions: $e')),
              data: (sessions) {
                final filtered = _statusFilter == 'all'
                    ? sessions
                    : sessions.where((s) => s.status == _statusFilter).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No sessions found for selected filter'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final session = filtered[index];
                    final isMorning = session.isMorning;

                    Color statusBgColor;
                    Color statusTextColor;
                    switch (session.status) {
                      case 'open':
                        statusBgColor = Colors.green.shade50;
                        statusTextColor = Colors.green.shade800;
                        break;
                      case 'scheduled':
                        statusBgColor = Colors.orange.shade50;
                        statusTextColor = Colors.orange.shade800;
                        break;
                      default:
                        statusBgColor = Colors.grey.shade200;
                        statusTextColor = Colors.grey.shade800;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isMorning ? Colors.amber.shade100 : Colors.indigo.shade100,
                              child: Icon(
                                isMorning ? Icons.wb_sunny : Icons.nightlight_round,
                                color: isMorning ? Colors.orange.shade800 : Colors.indigo.shade800,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${session.sessionType.toUpperCase()} TRIP',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Chip(
                                        label: Text(
                                          session.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: statusTextColor,
                                          ),
                                        ),
                                        backgroundColor: statusBgColor,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${session.serviceDate}',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                  if (session.opensAt != null)
                                    Text(
                                      'Opened: ${AppDateUtils.formatTime(session.opensAt!)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  if (session.closesAt != null)
                                    Text(
                                      'Closed: ${AppDateUtils.formatTime(session.closesAt!)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            // Action buttons
                            if (session.isScheduled)
                              FilledButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('Open Session'),
                                style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                                onPressed: () async {
                                  await ref.read(attendanceRepositoryProvider).openSession(session.id);
                                  ref.invalidate(_sessionsListProvider);
                                },
                              )
                            else if (session.isOpen)
                              FilledButton.icon(
                                icon: const Icon(Icons.stop, size: 16),
                                label: const Text('Close Session'),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                                onPressed: () async {
                                  await ref.read(attendanceRepositoryProvider).closeSession(session.id);
                                  ref.invalidate(_sessionsListProvider);
                                },
                              )
                            else
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reopen'),
                                onPressed: () async {
                                  await ref.read(attendanceRepositoryProvider).openSession(session.id);
                                  ref.invalidate(_sessionsListProvider);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    String selectedType = 'morning';
    DateTime selectedDate = DateTime.now();
    bool openImmediately = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Attendance Session'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Session Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'morning',
                      label: Text('Morning'),
                      icon: Icon(Icons.wb_sunny, size: 16),
                    ),
                    ButtonSegment(
                      value: 'evening',
                      label: Text('Evening'),
                      icon: Icon(Icons.nightlight_round, size: 16),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (val) => setDialogState(() => selectedType = val.first),
                ),
                const SizedBox(height: 20),
                const Text('Service Date', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open Session Immediately'),
                  subtitle: const Text('Conductors can begin scanning right away'),
                  value: openImmediately,
                  onChanged: (val) => setDialogState(() => openImmediately = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final dateStr =
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

                await ref.read(attendanceRepositoryProvider).createSession(
                      sessionType: selectedType,
                      serviceDate: dateStr,
                      status: openImmediately ? 'open' : 'scheduled',
                      opensAt: openImmediately ? DateTime.now() : null,
                    );
                ref.invalidate(_sessionsListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
