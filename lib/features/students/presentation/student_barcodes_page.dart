import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:college_bus_attendance/core/constants/app_constants.dart';
import '../data/student_repository.dart';
import '../domain/student.dart';

final studentBarcodesProvider =
    FutureProvider.autoDispose<List<Student>>((ref) async {
  return ref.read(studentRepositoryProvider).getAll();
});

class StudentBarcodesPage extends ConsumerStatefulWidget {
  const StudentBarcodesPage({super.key});

  @override
  ConsumerState<StudentBarcodesPage> createState() =>
      _StudentBarcodesPageState();
}

class _StudentBarcodesPageState extends ConsumerState<StudentBarcodesPage> {
  String _searchQuery = '';
  String? _selectedDept;
  String? _selectedYear;
  bool _useQrCode = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentBarcodesProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    void generateRandom() {
      ref.read(studentRepositoryProvider).generateRandomStudents(6);
      ref.invalidate(studentBarcodesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generated 6 new random student barcodes!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isMobile ? 'Barcodes & IDs' : 'Student Barcodes & ID Cards'),
        actions: [
          if (isMobile) ...[
            IconButton(
              icon: Icon(_useQrCode ? Icons.line_weight : Icons.qr_code_2),
              tooltip: _useQrCode ? 'Show 1D Barcode' : 'Show 2D QR Code',
              onPressed: () => setState(() => _useQrCode = !_useQrCode),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Generate Random Barcodes',
              onPressed: generateRandom,
            ),
            const SizedBox(width: 8),
          ] else ...[
            // Toggle Barcode / QR Code
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Code 128'),
                  icon: Icon(Icons.line_weight),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('QR Code'),
                  icon: Icon(Icons.qr_code_2),
                ),
              ],
              selected: {_useQrCode},
              onSelectionChanged: (set) {
                setState(() => _useQrCode = set.first);
              },
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Generate Random Barcodes'),
              onPressed: generateRandom,
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Filter bar
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name or roll no...',
                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                  // Dept filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedDept,
                        hint: const Text('All Departments'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Departments')),
                          DropdownMenuItem(
                              value: 'Computer Science',
                              child: Text('Computer Science')),
                          DropdownMenuItem(
                              value: 'Information Technology',
                              child: Text('Information Technology')),
                          DropdownMenuItem(
                              value: 'Electronics & Communication',
                              child: Text('Electronics & Comm.')),
                          DropdownMenuItem(
                              value: 'Mechanical Engineering',
                              child: Text('Mechanical Engg')),
                          DropdownMenuItem(
                              value: 'Electrical & Electronics',
                              child: Text('Electrical & Electronics')),
                          DropdownMenuItem(
                              value: 'Artificial Intelligence & DS',
                              child: Text('AI & Data Science')),
                        ],
                        onChanged: (val) => setState(() => _selectedDept = val),
                      ),
                    ),
                  ),
                  // Year filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedYear,
                        hint: const Text('All Years'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Years')),
                          DropdownMenuItem(value: 'I Year', child: Text('I Year')),
                          DropdownMenuItem(value: 'II Year', child: Text('II Year')),
                          DropdownMenuItem(value: 'III Year', child: Text('III Year')),
                          DropdownMenuItem(value: 'IV Year', child: Text('IV Year')),
                        ],
                        onChanged: (val) => setState(() => _selectedYear = val),
                      ),
                    ),
                  ),
                  // Printable HTML tip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.print, size: 16, color: Color(0xFFB45309)),
                        SizedBox(width: 6),
                        Text(
                          'Open web/student_barcodes.html to print all cards',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Barcode cards grid
              Expanded(
                child: studentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(color: Colors.red)),
                  ),
                  data: (students) {
                    final filtered = students.where((s) {
                      if (_searchQuery.isNotEmpty &&
                          !s.name.toLowerCase().contains(_searchQuery) &&
                          !s.rollNumber.toLowerCase().contains(_searchQuery)) {
                        return false;
                      }
                      if (_selectedDept != null && s.department != _selectedDept) {
                        return false;
                      }
                      if (_selectedYear != null &&
                          s.academicYear != _selectedYear) {
                        return false;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No students match the selected filters.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisExtent: 310,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final student = filtered[index];
                        return _buildIdCard(student);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdCard(Student student) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Column(
        children: [
          // College Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A), // Navy header
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppConstants.collegeName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BUS PASS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student Info Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              student.rollNumber,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            student.academicYear,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student.department,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Color(0xFF94A3B8)),
                  tooltip: 'Copy Roll Number',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: student.rollNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied ${student.rollNumber}')),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Barcode Display Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: _useQrCode
                    ? BarcodeWidget(
                        barcode: Barcode.qrCode(),
                        data: student.rollNumber,
                        width: 90,
                        height: 90,
                        color: Colors.black,
                      )
                    : BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: student.rollNumber,
                        width: double.infinity,
                        height: 65,
                        drawText: true,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
