import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:college_bus_attendance/features/auth/presentation/auth_provider.dart';
import 'package:college_bus_attendance/features/auth/data/auth_repository.dart';
import 'package:college_bus_attendance/features/attendance/data/attendance_repository.dart';
import 'package:college_bus_attendance/features/attendance/domain/attendance.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';
import 'package:college_bus_attendance/core/constants/app_constants.dart';

class ConductorHomePage extends ConsumerStatefulWidget {
  const ConductorHomePage({super.key});

  @override
  ConsumerState<ConductorHomePage> createState() => _ConductorHomePageState();
}

class _ConductorHomePageState extends ConsumerState<ConductorHomePage> {
  @override
  Widget build(BuildContext context) {
    final conductor = ref.watch(conductorInfoProvider);
    final theme = Theme.of(context);

    if (conductor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Text('Duty Session Active'),
              ],
            ),
            content: const Text(
              'To prevent accidental exits during bus service, the back button is disabled.\n\n'
              'You must stay in the app until you finish your shift. Do you want to log out now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay On Duty'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Log Out & Exit'),
              ),
            ],
          ),
        );

        if (shouldLogout == true && context.mounted) {
          ref.read(conductorInfoProvider.notifier).state = null;
          ref.read(adminLoggedInProvider.notifier).state = false;
          await ref.read(authRepositoryProvider).signOut();
          if (context.mounted) context.go('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppConstants.collegeName),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('End Shift & Log Out?'),
                    content: const Text(
                      'Are you sure you want to end your current duty session and log out?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  ref.read(conductorInfoProvider.notifier).state = null;
                  ref.read(adminLoggedInProvider.notifier).state = false;
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                }
              },
            ),
          ],
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conductor info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.person, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(conductor.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600)),
                            Text('Bus: ${conductor.busNumber}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500)),
                            Text(AppDateUtils.formatDateStr(
                                    AppDateUtils.todayServiceDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Sessions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _SessionCard(
                session: AppConstants.sessionMorning,
                icon: Icons.wb_sunny_outlined,
                color: const Color(0xFFF57F17),
              ),
              const SizedBox(height: 12),
              _SessionCard(
                session: AppConstants.sessionEvening,
                icon: Icons.nights_stay_outlined,
                color: const Color(0xFF1565C0),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _SessionCard extends ConsumerWidget {
  final String session;
  final IconData icon;
  final Color color;

  const _SessionCard({
    required this.session,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_todaySessionsProvider);

    return sessionsAsync.when(
      loading: () => _buildCard(context, ref, null, isLoading: true),
      error: (_, __) => _buildCard(context, ref, null),
      data: (sessions) {
        final match = sessions.where((s) => s.sessionType == session).firstOrNull;
        return _buildCard(context, ref, match);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    AttendanceSession? match, {
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final isOpen = match?.isOpen ?? false;
    final label = session == 'morning' ? 'Morning Session' : 'Evening Session';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (match != null && match.isOpen) {
            context.go('/scan/${match.id}/$session');
          } else {
            try {
              final repo = ref.read(attendanceRepositoryProvider);
              AttendanceSession active;
              if (match == null) {
                active = await repo.createSession(
                  sessionType: session,
                  serviceDate: AppDateUtils.todayServiceDate,
                  status: 'open',
                  opensAt: DateTime.now(),
                );
              } else {
                active = await repo.openSession(match.id);
              }
              ref.invalidate(_todaySessionsProvider);
              if (context.mounted) {
                context.go('/scan/${active.id}/$session');
              }
            } catch (_) {
              if (context.mounted) {
                context.go('/scan/session-$session-${AppDateUtils.todayServiceDate}/$session');
              }
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    if (isLoading)
                      const SizedBox(
                        height: 14,
                        width: 70,
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          match == null
                              ? 'TAP TO START'
                              : match.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOpen
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

final _todaySessionsProvider = FutureProvider.autoDispose((ref) {
  return ref.read(attendanceRepositoryProvider).getTodaySessions();
});
