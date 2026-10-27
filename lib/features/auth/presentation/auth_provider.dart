import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

// ── Current auth state ───────────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── Current user profile ─────────────────────────────────────────────────────
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Depend on auth state so this refreshes on sign-in / sign-out
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).getCurrentProfile();
});

// ── Admin login state ────────────────────────────────────────────────────────
final adminLoggedInProvider = StateProvider<bool>((ref) => false);
final currentAdminProfileProvider = StateProvider<UserProfile?>((ref) => null);

// ── Admin login notifier ─────────────────────────────────────────────────────
class AdminLoginNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> login(String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(authRepositoryProvider).signInAdmin(password);
      ref.read(adminLoggedInProvider.notifier).state = true;
      ref.read(currentAdminProfileProvider.notifier).state = profile;
    });
  }
}

final adminLoginProvider = AsyncNotifierProvider<AdminLoginNotifier, void>(
  AdminLoginNotifier.new,
);

// ── Conductor login notifier ─────────────────────────────────────────────────
class ConductorLoginState {
  final bool loading;
  final String? error;
  final ConductorInfo? conductor;
  const ConductorLoginState({this.loading = false, this.error, this.conductor});
  ConductorLoginState copyWith({bool? loading, String? error, ConductorInfo? conductor}) =>
      ConductorLoginState(
        loading: loading ?? this.loading,
        error: error,
        conductor: conductor ?? this.conductor,
      );
}

class ConductorLoginNotifier extends Notifier<ConductorLoginState> {
  @override
  ConductorLoginState build() => const ConductorLoginState();

  Future<bool> login({
    required String username,
    required String busNumber,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final info = await ref.read(authRepositoryProvider).signInConductor(
            username: username,
            busNumber: busNumber,
            password: password,
          );
      ref.read(conductorInfoProvider.notifier).state = info;
      state = state.copyWith(loading: false, conductor: info);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}

final conductorLoginProvider = NotifierProvider<ConductorLoginNotifier, ConductorLoginState>(
  ConductorLoginNotifier.new,
);

// ── Current conductor info (persisted from login) ────────────────────────────
final conductorInfoProvider = StateProvider<ConductorInfo?>((ref) => null);

