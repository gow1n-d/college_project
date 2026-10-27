class Bus {
  final String id;
  final String busNumber;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const Bus({
    required this.id,
    required this.busNumber,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory Bus.fromJson(Map<String, dynamic> j) => Bus(
        id: j['id'] as String,
        busNumber: j['bus_number'] as String,
        description: j['description'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'bus_number': busNumber,
        'description': description,
        'is_active': isActive,
      };
}

class ConductorBusAssignment {
  final String id;
  final String conductorId;
  final String busId;
  final String conductorName;
  final String busNumber;
  final DateTime validFrom;
  final DateTime? validUntil;
  final bool isActive;

  const ConductorBusAssignment({
    required this.id,
    required this.conductorId,
    required this.busId,
    required this.conductorName,
    required this.busNumber,
    required this.validFrom,
    this.validUntil,
    required this.isActive,
  });

  factory ConductorBusAssignment.fromJson(Map<String, dynamic> j) {
    final profile = j['profiles'] as Map<String, dynamic>?;
    final bus = j['buses'] as Map<String, dynamic>?;
    return ConductorBusAssignment(
      id: j['id'] as String,
      conductorId: j['conductor_id'] as String,
      busId: j['bus_id'] as String,
      conductorName: profile?['display_name'] as String? ?? '',
      busNumber: bus?['bus_number'] as String? ?? '',
      validFrom: DateTime.parse(j['valid_from'] as String),
      validUntil: j['valid_until'] != null
          ? DateTime.parse(j['valid_until'] as String)
          : null,
      isActive: j['is_active'] as bool? ?? true,
    );
  }
}
