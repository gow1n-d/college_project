import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/student.dart';

final studentRepositoryProvider = Provider((ref) => StudentRepository());

class StudentRepository {
  SupabaseClient? get _db {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Pre-seeded sample students with random departments, years, and barcodes
  static final List<Student> _localStudents = [
    Student(
      id: 'std-101',
      rollNumber: '21CS101',
      name: 'Arun Kumar',
      department: 'Computer Science',
      academicYear: 'IV Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-102',
      rollNumber: '22IT204',
      name: 'Priya Dharshini',
      department: 'Information Technology',
      academicYear: 'III Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 110)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-103',
      rollNumber: '23EC115',
      name: 'Karthik Raja',
      department: 'Electronics & Communication',
      academicYear: 'II Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-104',
      rollNumber: '21ME302',
      name: 'Sneha Menon',
      department: 'Mechanical Engineering',
      academicYear: 'IV Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-105',
      rollNumber: '22EE409',
      name: 'Rahul Varma',
      department: 'Electrical & Electronics',
      academicYear: 'III Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-106',
      rollNumber: '24CS045',
      name: 'Ananya Sharma',
      department: 'Computer Science',
      academicYear: 'I Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 70)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-107',
      rollNumber: '22CV108',
      name: 'Divya Bharathi',
      department: 'Civil Engineering',
      academicYear: 'III Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-108',
      rollNumber: '23AI021',
      name: 'Vignesh Swaminathan',
      department: 'Artificial Intelligence & DS',
      academicYear: 'II Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-109',
      rollNumber: '21BT014',
      name: 'Meera Krishnan',
      department: 'Biotechnology',
      academicYear: 'IV Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-110',
      rollNumber: '22CS330',
      name: 'Sanjay Govind',
      department: 'Computer Science',
      academicYear: 'III Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-111',
      rollNumber: '23IT119',
      name: 'Kavitha R',
      department: 'Information Technology',
      academicYear: 'II Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 'std-112',
      rollNumber: '21EC240',
      name: 'Balaji Natarajan',
      department: 'Electronics & Communication',
      academicYear: 'IV Year',
      busEligible: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<List<Student>> getAll({
    String? department,
    String? academicYear,
    bool? isActive,
  }) async {
    try {
      if (_db != null) {
        var query = _db!.from('students').select();
        if (department != null) query = query.eq('department', department) as dynamic;
        if (academicYear != null) query = query.eq('academic_year', academicYear) as dynamic;
        if (isActive != null) query = query.eq('is_active', isActive) as dynamic;
        final data = await (query as dynamic).order('roll_number', ascending: true);
        final remoteList =
            (data as List).map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();

        if (remoteList.isNotEmpty) {
          // Sync into local list
          for (final r in remoteList) {
            final idx = _localStudents.indexWhere((s) => s.rollNumber == r.rollNumber);
            if (idx >= 0) {
              _localStudents[idx] = r;
            } else {
              _localStudents.add(r);
            }
          }
        }
      }
    } catch (_) {
      // Remote table syncing or offline; proceed with in-memory list
    }

    var result = List<Student>.from(_localStudents);
    if (department != null) {
      result = result.where((s) => s.department == department).toList();
    }
    if (academicYear != null) {
      result = result.where((s) => s.academicYear == academicYear).toList();
    }
    if (isActive != null) {
      result = result.where((s) => s.isActive == isActive).toList();
    }
    result.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
    return result;
  }

  Future<Student?> findByRollNumber(String roll) async {
    final clean = roll.trim().toUpperCase();
    try {
      if (_db != null) {
        final data = await _db!
            .from('students')
            .select()
            .eq('roll_number', clean)
            .maybeSingle();
        if (data != null) {
          return Student.fromJson(data);
        }
      }
    } catch (_) {}

    return _localStudents.where((s) => s.rollNumber.toUpperCase() == clean).firstOrNull;
  }

  Future<Student> create(Student student) async {
    _localStudents.removeWhere((s) => s.rollNumber == student.rollNumber);
    _localStudents.insert(0, student);

    try {
      if (_db != null) {
        final data = await _db!
            .from('students')
            .insert(student.toInsertJson())
            .select()
            .single();
        return Student.fromJson(data);
      }
    } catch (_) {}
    return student;
  }

  Future<Student> update(String id, Map<String, dynamic> fields) async {
    fields['updated_at'] = DateTime.now().toIso8601String();
    final idx = _localStudents.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      final curr = _localStudents[idx];
      _localStudents[idx] = curr.copyWith(
        isActive: fields['is_active'] as bool?,
        busEligible: fields['bus_eligible'] as bool?,
      );
    }

    try {
      if (_db != null) {
        final data = await _db!
            .from('students')
            .update(fields)
            .eq('id', id)
            .select()
            .single();
        return Student.fromJson(data);
      }
    } catch (_) {}
    return _localStudents.firstWhere((s) => s.id == id);
  }

  /// Generates random sample students with realistic names, roll numbers, departments & years
  List<Student> generateRandomStudents(int count) {
    final firstNames = [
      'Aditya', 'Aishwarya', 'Akash', 'Deepak', 'Gowtham', 'Harini',
      'Ishwarya', 'Janani', 'Kishore', 'Lavanya', 'Manikandan', 'Naveen',
      'Pavithra', 'Pooja', 'Raghavan', 'Sai', 'Shreya', 'Siddharth', 'Varun', 'Vandana'
    ];
    final lastNames = [
      'R', 'S', 'M', 'Kumar', 'Sundaram', 'Iyer', 'Reddy', 'Patel',
      'Nair', 'Menon', 'Venkatesh', 'Prasad', 'Chandran', 'Babu', 'Pillai'
    ];
    final departments = [
      'Computer Science',
      'Information Technology',
      'Electronics & Communication',
      'Electrical & Electronics',
      'Mechanical Engineering',
      'Civil Engineering',
      'Artificial Intelligence & DS',
      'Biotechnology',
    ];
    final deptCodes = {
      'Computer Science': 'CS',
      'Information Technology': 'IT',
      'Electronics & Communication': 'EC',
      'Electrical & Electronics': 'EE',
      'Mechanical Engineering': 'ME',
      'Civil Engineering': 'CV',
      'Artificial Intelligence & DS': 'AI',
      'Biotechnology': 'BT',
    };
    final years = ['I Year', 'II Year', 'III Year', 'IV Year'];
    final yearToPrefix = {'I Year': '24', 'II Year': '23', 'III Year': '22', 'IV Year': '21'};

    final rand = Random();
    final newStudents = <Student>[];

    for (int i = 0; i < count; i++) {
      final fname = firstNames[rand.nextInt(firstNames.length)];
      final lname = lastNames[rand.nextInt(lastNames.length)];
      final fullName = '$fname $lname';
      final dept = departments[rand.nextInt(departments.length)];
      final year = years[rand.nextInt(years.length)];
      final code = deptCodes[dept] ?? 'CS';
      final yearPrefix = yearToPrefix[year] ?? '23';
      final rollSeq = (100 + rand.nextInt(899)).toString();
      final rollNumber = '$yearPrefix$code$rollSeq';

      if (!_localStudents.any((s) => s.rollNumber == rollNumber)) {
        final newStudent = Student(
          id: const Uuid().v4(),
          rollNumber: rollNumber,
          name: fullName,
          department: dept,
          academicYear: year,
          busEligible: true,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _localStudents.insert(0, newStudent);
        newStudents.add(newStudent);
      }
    }

    return newStudents;
  }

  /// UPSERT import: inserts or updates by roll_number
  Future<Map<String, int>> importStudents(List<Map<String, dynamic>> rows) async {
    int inserted = 0, updated = 0, failed = 0;
    for (final row in rows) {
      try {
        final roll = (row['roll_number'] as String).trim().toUpperCase();
        final existing = await findByRollNumber(roll);
        if (existing == null) {
          final s = Student(
            id: const Uuid().v4(),
            rollNumber: roll,
            name: row['name'] as String,
            academicYear: row['academic_year'] as String,
            department: row['department'] as String,
            busEligible: row['bus_eligible'] as bool? ?? true,
            isActive: row['is_active'] as bool? ?? true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _localStudents.insert(0, s);
          try {
            await _db?.from('students').insert(row);
          } catch (_) {}
          inserted++;
        } else {
          final idx = _localStudents.indexWhere((s) => s.rollNumber == roll);
          if (idx >= 0) {
            _localStudents[idx] = Student(
              id: existing.id,
              rollNumber: roll,
              name: row['name'] as String? ?? existing.name,
              academicYear: row['academic_year'] as String? ?? existing.academicYear,
              department: row['department'] as String? ?? existing.department,
              busEligible: row['bus_eligible'] as bool? ?? existing.busEligible,
              isActive: row['is_active'] as bool? ?? existing.isActive,
              createdAt: existing.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          try {
            await _db?.from('students').update(row).eq('id', existing.id);
          } catch (_) {}
          updated++;
        }
      } catch (_) {
        failed++;
      }
    }
    return {'inserted': inserted, 'updated': updated, 'failed': failed};
  }

  Future<List<String>> getDistinctDepartments() async {
    try {
      if (_db != null) {
        final data = await _db!
            .from('students')
            .select('department')
            .eq('is_active', true);
        final depts = (data as List)
            .map((e) => e['department'] as String)
            .toSet()
            .toList()
          ..sort();
        if (depts.isNotEmpty) return depts;
      }
    } catch (_) {}

    return _localStudents.map((e) => e.department).toSet().toList()..sort();
  }

  Future<List<String>> getDistinctYears() async {
    try {
      if (_db != null) {
        final data = await _db!
            .from('students')
            .select('academic_year')
            .eq('is_active', true);
        final years = (data as List)
            .map((e) => e['academic_year'] as String)
            .toSet()
            .toList()
          ..sort();
        if (years.isNotEmpty) return years;
      }
    } catch (_) {}

    return _localStudents.map((e) => e.academicYear).toSet().toList()..sort();
  }
}
