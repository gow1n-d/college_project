import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/bus.dart';

final busRepositoryProvider = Provider((ref) => BusRepository());

class BusRepository {
  final _db = Supabase.instance.client;

  Future<List<Bus>> getAll({bool? isActive}) async {
    var query = _db.from('buses').select();
    if (isActive != null) query = query.eq('is_active', isActive) as dynamic;
    final data = await (query as dynamic).order('bus_number', ascending: true);
    return (data as List).map((e) => Bus.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bus> create(String busNumber, {String? description}) async {
    final data = await _db
        .from('buses')
        .insert({'bus_number': busNumber.toUpperCase(), 'description': description})
        .select()
        .single();
    return Bus.fromJson(data);
  }

  Future<Bus> update(String id, Map<String, dynamic> fields) async {
    fields['updated_at'] = DateTime.now().toIso8601String();
    final data = await _db
        .from('buses')
        .update(fields)
        .eq('id', id)
        .select()
        .single();
    return Bus.fromJson(data);
  }

  Future<List<ConductorBusAssignment>> getAssignments({String? busId}) async {
    var query = _db.from('conductor_bus_assignments').select(
          'id, conductor_id, bus_id, valid_from, valid_until, is_active, '
          'profiles(display_name, username), buses(bus_number)',
        );
    if (busId != null) query = query.eq('bus_id', busId) as dynamic;
    final data = await (query as dynamic).order('created_at', ascending: false);
    return (data as List)
        .map((e) => ConductorBusAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> assignConductor({
    required String conductorId,
    required String busId,
    required DateTime validFrom,
    DateTime? validUntil,
  }) async {
    // Deactivate any existing active assignment for this conductor
    await _db
        .from('conductor_bus_assignments')
        .update({'is_active': false})
        .eq('conductor_id', conductorId)
        .eq('is_active', true);

    await _db.from('conductor_bus_assignments').insert({
      'conductor_id': conductorId,
      'bus_id': busId,
      'valid_from': validFrom.toIso8601String().split('T')[0],
      'valid_until': validUntil?.toIso8601String().split('T')[0],
      'is_active': true,
    });
  }
}
