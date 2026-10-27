class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String role; // 'admin' | 'conductor'
  final bool isActive;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isConductor => role == 'conductor';

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        username: j['username'] as String,
        displayName: j['display_name'] as String,
        role: j['role'] as String,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'role': role,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}

class ConductorInfo {
  final String id;
  final String displayName;
  final String username;
  final String busNumber;
  final String busId;

  const ConductorInfo({
    required this.id,
    required this.displayName,
    required this.username,
    required this.busNumber,
    required this.busId,
  });

  factory ConductorInfo.fromJson(Map<String, dynamic> j) => ConductorInfo(
        id: j['id'] as String,
        displayName: j['display_name'] as String,
        username: j['username'] as String,
        busNumber: j['bus_number'] as String,
        busId: j['bus_id'] as String,
      );
}
