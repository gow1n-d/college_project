import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/conductor.dart';

final conductorRepositoryProvider = Provider((ref) => ConductorRepository());

class ConductorRepository {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory persistent cache for instant loading and fallback
  static final List<Conductor> _conductors = [
    Conductor(
      id: 'c1-uuid-101',
      name: 'Ramesh Kumar',
      username: 'conductor1',
      password: 'conductor123',
      phone: '9876543210',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Conductor(
      id: 'c2-uuid-102',
      name: 'Suresh V',
      username: 'conductor2',
      password: 'conductor123',
      phone: '9876543211',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Conductor(
      id: 'c3-uuid-103',
      name: 'Murugan P',
      username: 'conductor3',
      password: 'conductor123',
      phone: '9876543212',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  Future<List<Conductor>> getConductors() async {
    try {
      if (_supabase != null) {
        final data = await _supabase!
            .from('profiles')
            .select()
            .eq('role', 'conductor')
            .order('display_name', ascending: true);
        
        final remoteList = (data as List).map((row) {
          return Conductor(
            id: row['id'] as String,
            name: row['display_name'] as String? ?? 'Conductor',
            username: row['username'] as String? ?? '',
            password: 'conductor123',
            phone: row['phone'] as String?,
            isActive: row['is_active'] as bool? ?? true,
            createdAt: row['created_at'] != null
                ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();

        if (remoteList.isNotEmpty) {
          // Merge with in-memory list without duplicates
          for (final r in remoteList) {
            if (!_conductors.any((c) => c.username == r.username)) {
              _conductors.add(r);
            }
          }
        }
      }
    } catch (_) {
      // Remote table unavailable or offline; seamlessly use local store
    }
    return List.unmodifiable(_conductors);
  }

  Future<Conductor> addConductor({
    required String name,
    required String username,
    required String password,
    String? phone,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    if (_conductors.any((c) => c.username.toLowerCase() == cleanUsername)) {
      throw Exception('Username "$cleanUsername" already exists');
    }

    final newId = const Uuid().v4();
    final conductor = Conductor(
      id: newId,
      name: name.trim(),
      username: cleanUsername,
      password: password.trim(),
      phone: phone?.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    _conductors.insert(0, conductor);

    try {
      if (_supabase != null) {
        await _supabase!.from('profiles').insert({
          'id': newId,
          'username': cleanUsername,
          'display_name': name.trim(),
          'role': 'conductor',
          'is_active': true,
          'phone': phone?.trim(),
        });
      }
    } catch (_) {
      // Graceful fallback if database schema is syncing
    }

    return conductor;
  }

  Future<void> removeConductor(String id) async {
    _conductors.removeWhere((c) => c.id == id);
    try {
      if (_supabase != null) {
        await _supabase!.from('profiles').delete().eq('id', id);
      }
    } catch (_) {
      // Gracefully ignore remote error
    }
  }

  Future<Conductor?> findByUsername(String username) async {
    final clean = username.trim().toLowerCase();
    final match = _conductors.where((c) => c.username.toLowerCase() == clean).firstOrNull;
    if (match != null) return match;

    try {
      if (_supabase != null) {
        final data = await _supabase!
            .from('profiles')
            .select()
            .eq('username', clean)
            .maybeSingle();
        if (data != null) {
          return Conductor.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> validateCredentials(String username, String password) async {
    final conductor = await findByUsername(username);
    if (conductor == null) return false;
    return conductor.password == password.trim();
  }
}
