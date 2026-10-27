import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../students/data/student_repository.dart';
import '../../students/domain/student.dart';

final _studentsProvider = FutureProvider.autoDispose((ref) {
  return ref.read(studentRepositoryProvider).getAll();
});

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(_studentsProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMobile ? 'Students' : 'Student Management'),
        actions: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'Import CSV',
              onPressed: () => context.push('/admin/students/import'),
            ),
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Add Student',
              onPressed: () => _showStudentDialog(context, null),
            ),
            const SizedBox(width: 8),
          ] else ...[
            FilledButton.icon(
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Import CSV'),
              onPressed: () => context.push('/admin/students/import'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Student'),
              onPressed: () => _showStudentDialog(context, null),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Student'),
              onPressed: () => _showStudentDialog(context, null),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or roll number…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) {
                final filtered = _search.isEmpty
                    ? students
                    : students.where((s) {
                        final q = _search.toLowerCase();
                        return s.name.toLowerCase().contains(q) ||
                            s.rollNumber.toLowerCase().contains(q);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No students found'),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Roll No.')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Dept')),
                      DataColumn(label: Text('Year')),
                      DataColumn(label: Text('Bus Eligible')),
                      DataColumn(label: Text('Active')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered
                        .map((s) => DataRow(cells: [
                              DataCell(Text(s.rollNumber)),
                              DataCell(Text(s.name)),
                              DataCell(Text(s.department)),
                              DataCell(Text(s.academicYear)),
                              DataCell(Icon(
                                s.busEligible
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color:
                                    s.busEligible ? Colors.green : Colors.grey,
                                size: 18,
                              )),
                              DataCell(Switch(
                                value: s.isActive,
                                onChanged: (v) async {
                                  await ref
                                      .read(studentRepositoryProvider)
                                      .update(s.id, {'is_active': v});
                                  ref.invalidate(_studentsProvider);
                                },
                              )),
                              DataCell(IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () =>
                                    _showStudentDialog(context, s),
                              )),
                            ]))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStudentDialog(BuildContext context, Student? existing) async {
    final rollCtrl =
        TextEditingController(text: existing?.rollNumber ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final yearCtrl =
        TextEditingController(text: existing?.academicYear ?? '');
    final deptCtrl =
        TextEditingController(text: existing?.department ?? '');
    bool eligible = existing?.busEligible ?? true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Student' : 'Edit Student'),
        content: StatefulBuilder(
          builder: (_, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existing == null)
                TextField(
                  controller: rollCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Roll Number'),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: yearCtrl,
                decoration:
                    const InputDecoration(labelText: 'Academic Year'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: eligible,
                title: const Text('Bus Eligible'),
                onChanged: (v) => setS(() => eligible = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(studentRepositoryProvider);
    if (existing == null) {
      await repo.create(Student(
        id: '',
        rollNumber: rollCtrl.text.trim().toUpperCase(),
        name: nameCtrl.text.trim(),
        academicYear: yearCtrl.text.trim(),
        department: deptCtrl.text.trim(),
        busEligible: eligible,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } else {
      await repo.update(existing.id, {
        'name': nameCtrl.text.trim(),
        'academic_year': yearCtrl.text.trim(),
        'department': deptCtrl.text.trim(),
        'bus_eligible': eligible,
      });
    }
    ref.invalidate(_studentsProvider);
  }
}
