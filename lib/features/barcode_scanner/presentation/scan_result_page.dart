import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:college_bus_attendance/features/barcode_scanner/data/scan_repository.dart';
import 'package:college_bus_attendance/app/theme.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';

class ScanResultPage extends StatelessWidget {
  final ScanResult result;

  const ScanResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccess = result.isSuccess;
    final isDuplicate = result.isDuplicate;
    final student = result.student;

    final statusColor = isSuccess
        ? AppTheme.success
        : isDuplicate
            ? AppTheme.warning
            : theme.colorScheme.error;

    final statusIcon = isSuccess
        ? Icons.check_circle_rounded
        : isDuplicate
            ? Icons.info_rounded
            : Icons.cancel_rounded;

    final statusLabel = isSuccess
        ? 'Attendance Recorded'
        : isDuplicate
            ? 'Already Marked'
            : 'Scan Failed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 72),
                    const SizedBox(height: 12),
                    Text(
                      statusLabel,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    if (result.scannedAt != null)
                      Text(
                        AppDateUtils.formatFull(result.scannedAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Student details (if available)
              if (student != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const Divider(),
                        _InfoRow('Name', student['name'] as String? ?? '--'),
                        _InfoRow('Roll Number',
                            student['roll_number'] as String? ?? '--'),
                        _InfoRow('Department',
                            student['department'] as String? ?? '--'),
                        _InfoRow('Year',
                            student['academic_year'] as String? ?? '--'),
                        if (result.busNumber != null)
                          _InfoRow('Bus', result.busNumber!),
                        if (result.sessionType != null)
                          _InfoRow('Session',
                              result.sessionType!.toUpperCase()),
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(),

              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Next Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
