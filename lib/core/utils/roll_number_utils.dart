import '../constants/app_constants.dart';

class RollNumberUtils {
  RollNumberUtils._();

  /// Normalise barcode value to canonical roll number
  static String normalize(String raw) => raw.trim().toUpperCase();

  /// Returns null if valid, error string if invalid
  static String? validate(String roll) {
    if (roll.isEmpty) return 'Roll number is empty';
    if (!AppConstants.rollNumberPattern.hasMatch(roll)) {
      return 'Invalid roll number format: $roll';
    }
    return null;
  }

  /// Returns true if normalized roll number is valid
  static bool isValid(String roll) => validate(normalize(roll)) == null;
}
