import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../students/data/student_repository.dart';

class StudentImportPage extends ConsumerStatefulWidget {
  const StudentImportPage({super.key});

  @override
  ConsumerState<StudentImportPage> createState() => _StudentImportPageState();
}

class _StudentImportPageState extends ConsumerState<StudentImportPage> {
  List<Map<String, String>> _validRows = [];
  List<Map<String, String>> _invalidRows = [];
  bool _previewing = false;
  bool _importing = false;
  Map<String, int>? _importResult;

  static const _requiredCols = ['roll_number', 'name', 'academic_year', 'department'];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final content = String.fromCharCodes(result.files.single.bytes!);
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    if (rows.isEmpty) {
      _showSnack('CSV file is empty');
      return;
    }

    // Parse headers (first row)
    final headers = rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
    for (final col in _requiredCols) {
      if (!headers.contains(col)) {
        _showSnack('Missing required column: $col');
        return;
      }
    }

    final valid = <Map<String, String>>[];
    final invalid = <Map<String, String>>[];
    final seenRolls = <String>{};

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < headers.length) continue;
      final map = {
        for (int j = 0; j < headers.length; j++)
          headers[j]: row[j].toString().trim()
      };

      final roll = map['roll_number']?.toUpperCase() ?? '';
      String? error;
      if (roll.isEmpty) error = 'Missing roll number';
      if (map['name']?.isEmpty ?? true) error = 'Missing name';
      if (map['academic_year']?.isEmpty ?? true) error = 'Missing academic_year';
      if (map['department']?.isEmpty ?? true) error = 'Missing department';
      if (seenRolls.contains(roll)) error = 'Duplicate roll number in file';

      if (error != null) {
        invalid.add({...map, '_error': error});
      } else {
        seenRolls.add(roll);
        map['roll_number'] = roll;
        valid.add(map);
      }
    }

    setState(() {
      _validRows = valid;
      _invalidRows = invalid;
      _previewing = true;
      _importResult = null;
    });
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await ref
          .read(studentRepositoryProvider)
          .importStudents(_validRows.map((r) => Map<String, dynamic>.from(r)).toList());
      setState(() => _importResult = result);
      _showSnack('Import complete!', success: true);
    } catch (e) {
      _showSnack('Import error: $e');
    } finally {
      setState(() => _importing = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import Students (CSV)')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CSV Format', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'roll_number,name,academic_year,department\n'
                      '23AD001,Alice,III Year,AI&DS\n'
                      '23AD002,Bob,III Year,CSE',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select CSV File'),
                    onPressed: _pickFile,
                  ),
                ],
              ),
            ),
          ),

          if (_previewing) ...[
            const SizedBox(height: 16),
            // Summary
            Row(
              children: [
                _PreviewBadge('${_validRows.length} Valid', Colors.green),
                const SizedBox(width: 12),
                _PreviewBadge('${_invalidRows.length} Invalid', Colors.red),
              ],
            ),
            const SizedBox(height: 16),

            // Valid rows
            if (_validRows.isNotEmpty) ...[
              Text('Valid Rows (will be imported)',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Roll No.')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Year')),
                      DataColumn(label: Text('Dept')),
                    ],
                    rows: _validRows
                        .take(50)
                        .map((r) => DataRow(cells: [
                              DataCell(Text(r['roll_number'] ?? '')),
                              DataCell(Text(r['name'] ?? '')),
                              DataCell(Text(r['academic_year'] ?? '')),
                              DataCell(Text(r['department'] ?? '')),
                            ]))
                        .toList(),
                  ),
                ),
              ),
              if (_validRows.length > 50)
                Text('… and ${_validRows.length - 50} more rows'),
            ],

            // Invalid rows
            if (_invalidRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Invalid Rows (will be skipped)',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: Colors.red)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: _invalidRows
                      .map((r) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            title: Text(r['name'] ?? r['roll_number'] ?? '--'),
                            subtitle: Text(r['_error'] ?? 'Unknown error'),
                          ))
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),
            if (_importResult != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Imported: ${_importResult!['inserted']}  '
                    'Updated: ${_importResult!['updated']}  '
                    'Failed: ${_importResult!['failed']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            if (_importResult == null && _validRows.isNotEmpty)
              FilledButton.icon(
                icon: _importing
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(_importing
                    ? 'Importing…'
                    : 'Confirm Import ${_validRows.length} Students'),
                onPressed: _importing ? null : _import,
              ),
          ],
        ],
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PreviewBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );
}
