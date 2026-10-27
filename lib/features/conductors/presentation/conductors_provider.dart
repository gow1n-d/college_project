import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/conductor_repository.dart';
import '../domain/conductor.dart';

class ConductorsNotifier extends AsyncNotifier<List<Conductor>> {
  @override
  Future<List<Conductor>> build() async {
    return ref.read(conductorRepositoryProvider).getConductors();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(conductorRepositoryProvider).getConductors(),
    );
  }

  Future<void> addConductor({
    required String name,
    required String username,
    required String password,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(conductorRepositoryProvider).addConductor(
            name: name,
            username: username,
            password: password,
            phone: phone,
          );
      return ref.read(conductorRepositoryProvider).getConductors();
    });
  }

  Future<void> removeConductor(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(conductorRepositoryProvider).removeConductor(id);
      return ref.read(conductorRepositoryProvider).getConductors();
    });
  }
}

final conductorsProvider =
    AsyncNotifierProvider<ConductorsNotifier, List<Conductor>>(
  ConductorsNotifier.new,
);
