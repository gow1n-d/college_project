class Conductor {
  final String id;
  final String name;
  final String username;
  final String password;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  const Conductor({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.phone,
    this.isActive = true,
    required this.createdAt,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'] as String,
      name: (json['name'] ?? json['display_name']) as String? ?? 'Conductor',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? 'conductor123',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'password': password,
        'phone': phone,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  Conductor copyWith({
    String? name,
    String? username,
    String? password,
    String? phone,
    bool? isActive,
  }) {
    return Conductor(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
