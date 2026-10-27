import 'package:flutter_test/flutter_test.dart';
import 'package:college_bus_attendance/features/conductors/data/conductor_repository.dart';
import 'package:college_bus_attendance/features/students/data/student_repository.dart';
import 'package:college_bus_attendance/features/auth/data/auth_repository.dart';
import 'package:college_bus_attendance/features/attendance/data/attendance_repository.dart';

void main() {
  group('Conductor Management Tests', () {
    test('Default static conductors exist and validate credentials', () async {
      final repo = ConductorRepository();
      final conductors = await repo.getConductors();
      expect(conductors.isNotEmpty, isTrue);

      final c1 = await repo.findByUsername('conductor1');
      expect(c1, isNotNull);
      expect(c1!.password, equals('conductor123'));

      final valid = await repo.validateCredentials('conductor1', 'conductor123');
      expect(valid, isTrue);

      final invalid = await repo.validateCredentials('conductor1', 'wrongpass');
      expect(invalid, isFalse);
    });

    test('Add and remove conductor', () async {
      final repo = ConductorRepository();
      final newConductor = await repo.addConductor(
        name: 'Test Conductor',
        username: 'test_c_${DateTime.now().millisecondsSinceEpoch}',
        password: 'testpass123',
        phone: '9998887770',
      );

      expect(newConductor.name, equals('Test Conductor'));
      final found = await repo.findByUsername(newConductor.username);
      expect(found, isNotNull);

      await repo.removeConductor(newConductor.id);
      final afterDelete = await repo.findByUsername(newConductor.username);
      expect(afterDelete, isNull);
    });
  });

  group('Student Random Barcode Tests', () {
    test('generateRandomStudents creates valid students with roll numbers', () {
      final repo = StudentRepository();
      final generated = repo.generateRandomStudents(5);

      expect(generated.length, equals(5));
      for (final s in generated) {
        expect(s.name.isNotEmpty, isTrue);
        expect(s.rollNumber.isNotEmpty, isTrue);
        expect(s.department.isNotEmpty, isTrue);
        expect(s.academicYear.isNotEmpty, isTrue);
      }
    });

    test('findByRollNumber retrieves existing and sample students', () async {
      final repo = StudentRepository();
      final student = await repo.findByRollNumber('21CS101');
      expect(student, isNotNull);
      expect(student!.name, equals('Arun Kumar'));
      expect(student.department, equals('Computer Science'));
      expect(student.academicYear, equals('IV Year'));
    });
  });

  group('Authentication and Session Fallback Tests', () {
    test('Conductor signInConductor validates static conductor and assigns bus', () async {
      final authRepo = AuthRepository();
      final info = await authRepo.signInConductor(
        username: 'conductor1',
        busNumber: 'BUS-05',
        password: 'conductor123',
      );
      expect(info.username, equals('conductor1'));
      expect(info.busNumber, equals('BUS-05'));
      expect(info.displayName, equals('Ramesh Kumar'));
    });

    test('Admin fallback login allows superadmin password without Supabase session', () async {
      final authRepo = AuthRepository();
      final admin = await authRepo.signInAdmin('superadmin');
      expect(admin.role, equals('admin'));
      expect(admin.isAdmin, isTrue);
      expect(admin.displayName, equals('Administrator'));
    });

    test('AttendanceRepository returns fallback sessions when offline or without DB session', () async {
      final attendanceRepo = AttendanceRepository();
      final sessions = await attendanceRepo.getTodaySessions();
      expect(sessions.isNotEmpty, isTrue);
      expect(sessions.any((s) => s.sessionType == 'morning'), isTrue);
      expect(sessions.any((s) => s.sessionType == 'evening'), isTrue);
    });
  });
}

