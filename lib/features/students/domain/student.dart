class Student {
  final String id;
  final String rollNumber;
  final String name;
  final String academicYear;
  final String department;
  final bool busEligible;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.rollNumber,
    required this.name,
    required this.academicYear,
    required this.department,
    required this.busEligible,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'] as String,
        rollNumber: j['roll_number'] as String,
        name: j['name'] as String,
        academicYear: j['academic_year'] as String,
        department: j['department'] as String,
        busEligible: j['bus_eligible'] as bool? ?? true,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : DateTime.now(),
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : (j['created_at'] != null
                ? DateTime.parse(j['created_at'] as String)
                : DateTime.now()),
      );

  Map<String, dynamic> toInsertJson() => {
        'roll_number': rollNumber,
        'name': name,
        'academic_year': academicYear,
        'department': department,
        'bus_eligible': busEligible,
        'is_active': isActive,
      };

  Student copyWith({bool? isActive, bool? busEligible}) => Student(
        id: id,
        rollNumber: rollNumber,
        name: name,
        academicYear: academicYear,
        department: department,
        busEligible: busEligible ?? this.busEligible,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
