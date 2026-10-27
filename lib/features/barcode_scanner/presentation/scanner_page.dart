import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:college_bus_attendance/features/auth/presentation/auth_provider.dart';
import 'package:college_bus_attendance/features/barcode_scanner/data/scan_repository.dart';
import 'package:college_bus_attendance/core/constants/app_constants.dart';
import 'package:college_bus_attendance/core/errors/app_exception.dart';
import 'package:college_bus_attendance/core/utils/roll_number_utils.dart';
import 'package:college_bus_attendance/core/utils/date_utils.dart';
import 'package:college_bus_attendance/features/attendance/domain/attendance.dart';
import 'scan_result_page.dart';

class ScannerPage extends ConsumerStatefulWidget {
  final String sessionId;
  final String sessionType;

  const ScannerPage({
    super.key,
    required this.sessionId,
    required this.sessionType,
  });

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    torchEnabled: false,
    returnImage: false,
  );

  late String _activeSessionType;
  late String _activeSessionId;

  bool _processing = false;
  String? _lastProcessed;
  DateTime? _lastScanTime;
  List<AttendanceRecord> _recentScans = [];
  int _scanCount = 0;
  bool _paused = false;
  ScanResult? _latestResult;

  @override
  void initState() {
    super.initState();
    _activeSessionType = widget.sessionType;
    _activeSessionId = widget.sessionId;
    _loadRecentScans();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecentScans() async {
    try {
      final records =
          await ref.read(scanRepositoryProvider).getMyRecords(_activeSessionId);
      if (mounted) {
        setState(() {
          _recentScans = records;
          _scanCount = records.length;
        });
      }
    } catch (_) {}
  }

  void _switchMode(String newMode) {
    if (_activeSessionType == newMode) return;
    setState(() {
      _activeSessionType = newMode;
      _activeSessionId = 'session-$newMode-${AppDateUtils.todayServiceDate}';
      _latestResult = null;
    });
    _loadRecentScans();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newMode == 'morning'
              ? '☀️ Switched to Morning Pickup Mode'
              : '🌙 Switched to Evening Drop Mode',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;

    // Debounce — prevent re-processing same code too fast
    final now = DateTime.now();
    if (_lastProcessed == raw &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < AppConstants.scanDebounce) {
      return;
    }

    if (_processing || _paused) return;

    final roll = RollNumberUtils.normalize(raw);
    final validationError = RollNumberUtils.validate(roll);
    if (validationError != null) return; // silently skip invalid formats

    HapticFeedback.lightImpact();
    _lastProcessed = raw;
    _lastScanTime = now;
    await _processRoll(roll);
  }

  Future<void> _processRoll(String roll) async {
    setState(() => _processing = true);
    final conductor = ref.read(conductorInfoProvider);

    try {
      final result = await ref.read(scanRepositoryProvider).recordAttendance(
            rollNumber: roll,
            sessionId: _activeSessionId,
            idempotencyKey: const Uuid().v4(),
            busNumber: conductor?.busNumber,
            sessionType: _activeSessionType,
            conductorName: conductor?.displayName,
            conductorId: conductor?.id,
            busId: conductor?.busId,
          );

      if (mounted) {
        if (result.isSuccess) {
          HapticFeedback.mediumImpact();
        } else if (result.isDuplicate) {
          HapticFeedback.vibrate();
        }
        setState(() {
          _latestResult = result;
        });
        await _loadRecentScans();
      }
    } on NotFoundException {
      HapticFeedback.heavyImpact();
      if (mounted) _showSnack('Student not found for roll: $roll', isError: true);
    } on SessionClosedException {
      HapticFeedback.heavyImpact();
      if (mounted) {
        _showSnack('Session is closed. Contact admin.', isError: true);
      }
    } on NetworkException {
      HapticFeedback.heavyImpact();
      if (mounted) _showSnack('No connection. Check network.', isError: true);
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showManualEntryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Roll Number Manually'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Roll Number',
            hintText: 'e.g. 21CS101, 22IT204',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          onSubmitted: (val) {
            Navigator.of(ctx).pop();
            if (val.trim().isNotEmpty) {
              _processRoll(RollNumberUtils.normalize(val.trim()));
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (ctrl.text.trim().isNotEmpty) {
                _processRoll(RollNumberUtils.normalize(ctrl.text.trim()));
              }
            },
            child: const Text('Submit Attendance'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.directions_bus, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Active Duty Session'),
          ],
        ),
        content: const Text(
          'Your bus duty is active.\n\nDo you want to return to the Duty Home screen, or stay in Scanner Mode?\n\n(To finish your shift, please log out from the Home screen.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay in Scanner'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      context.go('/home');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conductor = ref.watch(conductorInfoProvider);
    final isMorning = _activeSessionType == 'morning';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Return to Duty Home',
            onPressed: _onWillPop,
          ),
          title: Text(
            isMorning ? '☀️ Morning Pickup Mode' : '🌙 Evening Drop Mode',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              tooltip: _paused ? 'Resume' : 'Pause',
              onPressed: () {
                setState(() => _paused = !_paused);
                _paused ? _controller.stop() : _controller.start();
              },
            ),
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, value, __) => IconButton(
                icon: Icon(value.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off),
                tooltip: 'Toggle torch',
                onPressed: _controller.toggleTorch,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_outlined),
              tooltip: 'Enter Roll Manually',
              onPressed: _showManualEntryDialog,
            ),
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Summary',
              onPressed: () => context.push('/summary/$_activeSessionId'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Session Mode Switcher Bar
            Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Mode Segmented control
                  Expanded(
                    child: SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        selectedBackgroundColor: isMorning
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF3B82F6),
                        selectedForegroundColor: Colors.white,
                        foregroundColor: Colors.white70,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: 'morning',
                          label: Text('Morning Pickup'),
                          icon: Icon(Icons.wb_sunny_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: 'evening',
                          label: Text('Evening Drop'),
                          icon: Icon(Icons.nights_stay_outlined, size: 16),
                        ),
                      ],
                      selected: {_activeSessionType},
                      onSelectionChanged: (set) => _switchMode(set.first),
                    ),
                  ),
                ],
              ),
            ),

            // Conductor status bar
            Container(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: theme.colorScheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Bus: ${conductor?.busNumber ?? 'BUS-01'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '(${conductor?.displayName ?? 'Conductor'})',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.verified, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '$_scanCount Scanned',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Camera preview
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onBarcodeDetected,
                  ),
                  // Viewfinder frame
                  Center(
                    child: Container(
                      width: 270,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _latestResult != null && _latestResult!.isSuccess
                              ? Colors.greenAccent
                              : Colors.white,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_processing)
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                  if (_paused)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause_circle, color: Colors.white, size: 64),
                            SizedBox(height: 8),
                            Text('Scanner Paused',
                                style: TextStyle(color: Colors.white, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),

                  // Prompt text overlay
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point camera at student ID barcode / QR',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scanned Student Details Banner (when student scanned)
            if (_latestResult != null && _latestResult!.student != null)
              _ScannedStudentCard(
                result: _latestResult!,
                onDismiss: () => setState(() => _latestResult = null),
                onViewFull: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScanResultPage(result: _latestResult!),
                    ),
                  );
                },
              ),

            // Recent scans header and list
            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.history, size: 18, color: Color(0xFF475569)),
                          const SizedBox(width: 6),
                          Text(
                            'Recent Students Checked-In (${_recentScans.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Live Synced with Admin',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _recentScans.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner,
                                      size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'No students scanned for this mode yet.\nScan ID card to register attendance.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _recentScans.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 56),
                              itemBuilder: (_, i) {
                                final r = _recentScans[i];
                                final scanTime =
                                    '${r.scannedAt.hour.toString().padLeft(2, '0')}:${r.scannedAt.minute.toString().padLeft(2, '0')}:${r.scannedAt.second.toString().padLeft(2, '0')}';
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFDCFCE7),
                                    child: Text(
                                      (r.studentName != null && r.studentName!.isNotEmpty)
                                          ? r.studentName![0]
                                          : 'S',
                                      style: const TextStyle(
                                        color: Color(0xFF15803D),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    r.studentName ?? 'Student',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${r.scannedRollNumber} • ${r.studentDepartment ?? 'General'} (${r.studentYear ?? 'Year'})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        scanTime,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        '✓ Recorded',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prominent Scanned Student Details Card ──────────────────────────────────
class _ScannedStudentCard extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onDismiss;
  final VoidCallback onViewFull;

  const _ScannedStudentCard({
    required this.result,
    required this.onDismiss,
    required this.onViewFull,
  });

  @override
  Widget build(BuildContext context) {
    final s = result.student!;
    final isSuccess = result.isSuccess;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.warning_amber,
                        size: 14,
                        color: isSuccess
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSuccess ? 'ATTENDANCE RECORDED' : 'ALREADY MARKED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSuccess
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              s['name'] as String? ?? 'Student Name',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Roll No: ${s['roll_number']} • Department: ${s['department']}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Year: ${s['academic_year']} | Bus: ${result.busNumber ?? 'Assigned'} | Mode: ${(result.sessionType ?? 'Daily').toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

