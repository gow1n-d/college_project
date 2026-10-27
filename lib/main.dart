import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 40,
    ),
  );
  runApp(const ProviderScope(child: ConductorApp()));
}

class ConductorApp extends ConsumerWidget {
  const ConductorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(conductorRouterProvider);
    return MaterialApp.router(
      title: 'College Bus Attendance',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
