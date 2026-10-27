import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/admin_login_page.dart';
import '../features/auth/presentation/conductor_login_page.dart';
import '../features/conductor/presentation/conductor_home_page.dart';
import '../features/barcode_scanner/presentation/scanner_page.dart';
import '../features/conductor/presentation/session_summary_page.dart';
import '../features/admin_dashboard/presentation/dashboard_page.dart';
import '../features/conductors/presentation/conductors_page.dart';
import '../features/students/presentation/students_page.dart';
import '../features/students/presentation/student_barcodes_page.dart';
import '../features/students/presentation/student_import_page.dart';
import '../features/buses/presentation/buses_page.dart';
import '../features/sessions/presentation/sessions_page.dart';
import '../features/reports/presentation/reports_page.dart';

// Conductor app router (Mobile app supporting Conductor + Admin logins)
final conductorRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final conductor = ref.watch(conductorInfoProvider);
  final isAdminLoggedIn = ref.watch(adminLoggedInProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final hasSupabaseSession = authState.valueOrNull?.session != null;
      final isConductorLoggedIn = conductor != null;
      final isLoggedIn = hasSupabaseSession || isConductorLoggedIn || isAdminLoggedIn;
      final onLogin = state.matchedLocation == '/login' || state.matchedLocation == '/admin/login';

      if (!isLoggedIn && !onLogin) {
        return '/login';
      }

      if (isLoggedIn && onLogin) {
        if (isAdminLoggedIn) {
          return '/admin/dashboard';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const ConductorLoginPage()),
      GoRoute(path: '/admin/login', redirect: (_, __) => '/login'),
      GoRoute(path: '/home', builder: (_, __) => const ConductorHomePage()),
      GoRoute(
        path: '/scan/:sessionId/:sessionType',
        builder: (_, state) => ScannerPage(
          sessionId: state.pathParameters['sessionId']!,
          sessionType: state.pathParameters['sessionType']!,
        ),
      ),
      GoRoute(
        path: '/summary/:sessionId',
        builder: (_, state) =>
            SessionSummaryPage(sessionId: state.pathParameters['sessionId']!),
      ),
      // Admin dashboard routes on mobile
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/admin/dashboard',
              builder: (_, __) => const DashboardPage()),
          GoRoute(
              path: '/admin/conductors',
              builder: (_, __) => const ConductorsPage()),
          GoRoute(
              path: '/admin/barcodes',
              builder: (_, __) => const StudentBarcodesPage()),
          GoRoute(
              path: '/admin/students',
              builder: (_, __) => const StudentsPage()),
          GoRoute(
              path: '/admin/students/import',
              builder: (_, __) => const StudentImportPage()),
          GoRoute(
              path: '/admin/buses', builder: (_, __) => const BusesPage()),
          GoRoute(
              path: '/admin/sessions',
              builder: (_, __) => const SessionsPage()),
          GoRoute(
              path: '/admin/reports', builder: (_, __) => const ReportsPage()),
        ],
      ),
    ],
  );
});

// Admin dashboard router (Web)
final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isAdminLoggedIn = ref.watch(adminLoggedInProvider);

  return GoRouter(
    initialLocation: '/admin/login',
    redirect: (context, state) {
      final isLoggedIn = (authState.valueOrNull?.session != null) || isAdminLoggedIn;
      final onLogin = state.matchedLocation == '/admin/login' || state.matchedLocation == '/login';
      if (!isLoggedIn && !onLogin) return '/admin/login';
      if (isLoggedIn && onLogin) return '/admin/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginPage()),
      GoRoute(path: '/login', redirect: (_, __) => '/admin/login'),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/admin/dashboard',
              builder: (_, __) => const DashboardPage()),
          GoRoute(
              path: '/admin/conductors',
              builder: (_, __) => const ConductorsPage()),
          GoRoute(
              path: '/admin/barcodes',
              builder: (_, __) => const StudentBarcodesPage()),
          GoRoute(
              path: '/admin/students',
              builder: (_, __) => const StudentsPage()),
          GoRoute(
              path: '/admin/students/import',
              builder: (_, __) => const StudentImportPage()),
          GoRoute(
              path: '/admin/buses', builder: (_, __) => const BusesPage()),
          GoRoute(
              path: '/admin/sessions',
              builder: (_, __) => const SessionsPage()),
          GoRoute(
              path: '/admin/reports', builder: (_, __) => const ReportsPage()),
        ],
      ),
    ],
  );
});

// Admin shell with navigation rail
class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const List<({IconData icon, IconData activeIcon, String label, String path})> items = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      path: '/admin/dashboard',
    ),
    (
      icon: Icons.badge_outlined,
      activeIcon: Icons.badge,
      label: 'Conductors',
      path: '/admin/conductors',
    ),
    (
      icon: Icons.qr_code_2_outlined,
      activeIcon: Icons.qr_code_2,
      label: 'Barcodes',
      path: '/admin/barcodes',
    ),
    (
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Students',
      path: '/admin/students',
    ),
    (
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
      label: 'Buses',
      path: '/admin/buses',
    ),
    (
      icon: Icons.schedule_outlined,
      activeIcon: Icons.schedule,
      label: 'Sessions',
      path: '/admin/sessions',
    ),
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Reports',
      path: '/admin/reports',
    ),
  ];

  void _showMoreSheet(BuildContext context, WidgetRef ref, int selectedIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(Icons.admin_panel_settings, color: Color(0xFF1D4ED8)),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Menu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'College Bus Attendance System',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.directions_bus, color: Color(0xFF1D4ED8)),
                  title: const Text('Buses & Fleet', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Manage buses and route numbers'),
                  selected: selectedIndex == 4,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/admin/buses');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule, color: Color(0xFFD97706)),
                  title: const Text('Attendance Sessions', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('View and control morning & evening shifts'),
                  selected: selectedIndex == 5,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/admin/sessions');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Color(0xFF7C3AED)),
                  title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Export CSV and view trends'),
                  selected: selectedIndex == 6,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/admin/reports');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                  title: const Text(
                    'Logout Administrator',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    ref.read(adminLoggedInProvider.notifier).state = false;
                    ref.read(conductorInfoProvider.notifier).state = null;
                    ref.read(currentAdminProfileProvider.notifier).state = null;
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final selectedIndex = items.indexWhere((i) => location.startsWith(i.path));

    if (isMobile) {
      // ── MOBILE LAYOUT (Full Screen Child with Responsive Bottom Navigation) ──
      final bottomNavIndex = selectedIndex < 0 ? 0 : (selectedIndex > 3 ? 4 : selectedIndex);

      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          height: 64,
          elevation: 8,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDBEAFE),
          selectedIndex: bottomNavIndex,
          onDestinationSelected: (idx) {
            if (idx == 4) {
              _showMoreSheet(context, ref, selectedIndex);
            } else {
              context.go(items[idx].path);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Color(0xFF334155)),
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFF1D4ED8)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge_outlined, color: Color(0xFF334155)),
              selectedIcon: Icon(Icons.badge, color: Color(0xFF1D4ED8)),
              label: 'Conductors',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_2_outlined, color: Color(0xFF334155)),
              selectedIcon: Icon(Icons.qr_code_2, color: Color(0xFF1D4ED8)),
              label: 'Barcodes',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: Color(0xFF334155)),
              selectedIcon: Icon(Icons.people, color: Color(0xFF1D4ED8)),
              label: 'Students',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_rounded, color: Color(0xFF334155)),
              selectedIcon: Icon(Icons.menu_open_rounded, color: Color(0xFF1D4ED8)),
              label: 'More',
            ),
          ],
        ),
      );
    }

    // ── DESKTOP / TABLET LAYOUT (Side Navigation Rail) ───────────────────────
    return Scaffold(
      body: Row(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      minWidth: 96,
                      groupAlignment: -1.0,
                      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                      onDestinationSelected: (i) => context.go(items[i].path),
                      labelType: NavigationRailLabelType.all,
                      useIndicator: true,
                      indicatorColor: const Color(0xFFE0E7FF),
                      selectedLabelTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3730A3),
                        height: 1.3,
                      ),
                      unselectedLabelTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.directions_bus_filled,
                                color: Color(0xFF2563EB),
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'COLLEGE BUS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 16),
                        child: IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
                          tooltip: 'Logout',
                          onPressed: () async {
                            ref.read(adminLoggedInProvider.notifier).state = false;
                            ref.read(conductorInfoProvider.notifier).state = null;
                            ref.read(currentAdminProfileProvider.notifier).state = null;
                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                        ),
                      ),
                      destinations: items
                          .map((i) => NavigationRailDestination(
                                icon: Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Icon(i.icon, size: 22, color: const Color(0xFF64748B)),
                                ),
                                selectedIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Icon(i.activeIcon, size: 22, color: const Color(0xFF3730A3)),
                                ),
                                label: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    i.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
          Expanded(child: child),
        ],
      ),
    );
  }
}
