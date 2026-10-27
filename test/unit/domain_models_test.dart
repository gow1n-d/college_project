import 'package:flutter_test/flutter_test.dart';
import 'package:college_bus_attendance/core/constants/app_constants.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';
import 'package:college_bus_attendance/core/utils/roll_number_utils.dart';
import 'package:college_bus_attendance/features/students/domain/student.dart';
import 'package:college_bus_attendance/features/buses/domain/bus.dart';
import 'package:college_bus_attendance/features/attendance/domain/attendance.dart';

void main() {
  group('Roll Number Validation Tests', () {
    test('Valid uppercase alphanumeric roll numbers pass regex', () {
      expect(AppConstants.rollNumberPattern.hasMatch('21CS001'), isTrue);
      expect(AppConstants.rollNumberPattern.hasMatch('MECH105'), isTrue);
      expect(AppConstants.rollNumberPattern.hasMatch('IT2024'), isTrue);
    });

    test('Invalid roll numbers fail regex', () {
      expect(AppConstants.rollNumberPattern.hasMatch(''), isFalse);
      expect(AppConstants.rollNumberPattern.hasMatch('ab'), isFalse); // too short
      expect(AppConstants.rollNumberPattern.hasMatch('21cs001'), isFalse); // lowercase without normalization
      expect(AppConstants.rollNumberPattern.hasMatch('ROLL-001'), isFalse); // hyphen
    });

    test('RollNumberUtils normalizes whitespace and lowercase', () {
      expect(RollNumberUtils.normalize(' 21cs001 '), equals('21CS001'));
      expect(RollNumberUtils.isValid(' 21cs001 '), isTrue);
      expect(RollNumberUtils.isValid('!invalid!'), isFalse);
    });
  });

  group('Student Model Tests', () {
    test('Student parses from JSON correctly', () {
      final json = {
        'id': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        'roll_number': '21CS001',
        'name': 'John Doe',
        'academic_year': '3rd Year',
        'department': 'Computer Science',
        'bus_eligible': true,
        'is_active': true,
        'created_at': '2026-01-01T08:00:00Z',
      };

      final student = Student.fromJson(json);
      expect(student.rollNumber, equals('21CS001'));
      expect(student.name, equals('John Doe'));
      expect(student.busEligible, isTrue);
      expect(student.isActive, isTrue);
    });

    test('Student toInsertJson serializes correctly', () {
      final now = DateTime(2026, 1, 1);
      final student = Student(
        id: 'temp-id',
        rollNumber: '21CS002',
        name: 'Jane Smith',
        academicYear: '2nd Year',
        department: 'Information Technology',
        busEligible: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final insertMap = student.toInsertJson();
      expect(insertMap['roll_number'], equals('21CS002'));
      expect(insertMap['name'], equals('Jane Smith'));
      expect(insertMap['bus_eligible'], isTrue);
    });
  });

  group('Bus Model Tests', () {
    test('Bus parses from JSON correctly', () {
      final json = {
        'id': 'bus-123',
        'bus_number': 'BUS-01',
        'description': 'Main Campus Route',
        'is_active': true,
        'created_at': '2026-01-01T08:00:00Z',
      };

      final bus = Bus.fromJson(json);
      expect(bus.busNumber, equals('BUS-01'));
      expect(bus.description, equals('Main Campus Route'));
      expect(bus.isActive, isTrue);
    });
  });

  group('Attendance Session Tests', () {
    test('AttendanceSession status flags work accurately', () {
      final sessionOpen = AttendanceSession(
        id: 's-1',
        sessionType: 'morning',
        serviceDate: '2026-10-27',
        status: 'open',
        opensAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(sessionOpen.isOpen, isTrue);
      expect(sessionOpen.isClosed, isFalse);
      expect(sessionOpen.isScheduled, isFalse);
      expect(sessionOpen.isMorning, isTrue);

      final sessionClosed = AttendanceSession(
        id: 's-2',
        sessionType: 'evening',
        serviceDate: '2026-10-27',
        status: 'closed',
        closesAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(sessionClosed.isOpen, isFalse);
      expect(sessionClosed.isClosed, isTrue);
      expect(sessionClosed.isMorning, isFalse);
    });
  });

  group('Date Utilities Tests', () {
    test('Date formatting parses accurately', () {
      final date = DateTime(2026, 10, 27, 8, 30);
      expect(AppDateUtils.formatDate(date), equals('27 Oct 2026'));
      expect(AppDateUtils.formatTime(date), equals('08:30 AM'));
      expect(AppDateUtils.todayServiceDate, isNotEmpty);
    });
  });
}
