class AppConstants {
  AppConstants._();

  static const String collegeName = 'College Bus Attendance';
  static const String collegeTimezone = 'Asia/Kolkata';

  // Admin auth
  static const String adminEmail = 'admin@college-bus.local';

  // Roll number: uppercase alphanumeric, 5-10 chars
  static final RegExp rollNumberPattern = RegExp(r'^[A-Z0-9]{4,12}$');

  // Session types
  static const String sessionMorning = 'morning';
  static const String sessionEvening = 'evening';

  // Offline queue max pending records
  static const int maxOfflineQueueSize = 500;

  // Connectivity check interval
  static const Duration connectivityPollInterval = Duration(seconds: 10);

  // Scanner debounce — prevent re-processing same barcode
  static const Duration scanDebounce = Duration(seconds: 2);

  // Supported barcode formats (passed to mobile_scanner)
  // College ID cards typically use Code 128 or QR
  static const List<String> supportedBarcodeFormats = [
    'qrCode', 'code128', 'code39', 'ean13', 'dataMatrix', 'pdf417',
  ];
}
