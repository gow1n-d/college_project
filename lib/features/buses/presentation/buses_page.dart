import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bus_repository.dart';
import '../domain/bus.dart';

final _busesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(busRepositoryProvider).getAll();
});

final _assignmentsProvider = FutureProvider.autoDispose((ref) {
  return ref.read(busRepositoryProvider).getAssignments();
});

class BusesPage extends ConsumerStatefulWidget {
  const BusesPage({super.key});

  @override
  ConsumerState<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends ConsumerState<BusesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(_busesProvider);
    final assignmentsAsync = ref.watch(_assignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus & Conductor Fleet'),
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.start,
          isScrollable: true,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bus, size: 20),
                  SizedBox(width: 8),
                  Text('Buses'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.badge, size: 20),
                  SizedBox(width: 8),
                  Text('Conductor Assignments'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Bus'),
            onPressed: () => _showBusDialog(context, null),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Assign Conductor'),
            onPressed: () => _showAssignDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Buses Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by bus number or description…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Expanded(
                child: busesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (buses) {
                    final filtered = _search.isEmpty
                        ? buses
                        : buses.where((b) {
                            final q = _search.toLowerCase();
                            return b.busNumber.toLowerCase().contains(q) ||
                                (b.description?.toLowerCase().contains(q) ?? false);
                          }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No buses found'),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Bus Number')),
                            DataColumn(label: Text('Route / Description')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Created Date')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filtered.map((b) {
                            return DataRow(cells: [
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_bus, size: 18, color: Colors.indigo),
                                  const SizedBox(width: 8),
                                  Text(b.busNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              )),
                              DataCell(Text(b.description ?? '—')),
                              DataCell(Chip(
                                label: Text(
                                  b.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: b.isActive ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                                backgroundColor: b.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                visualDensity: VisualDensity.compact,
                              )),
                              DataCell(Text(
                                '${b.createdAt.year}-${b.createdAt.month.toString().padLeft(2, '0')}-${b.createdAt.day.toString().padLeft(2, '0')}',
                              )),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    tooltip: 'Edit Bus',
                                    onPressed: () => _showBusDialog(context, b),
                                  ),
                                  Switch(
                                    value: b.isActive,
                                    onChanged: (active) async {
                                      await ref.read(busRepositoryProvider).update(b.id, {'is_active': active});
                                      ref.invalidate(_busesProvider);
                                    },
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Assignments Tab
          assignmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (assignments) {
              if (assignments.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No conductor assignments recorded yet'),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Conductor')),
                      DataColumn(label: Text('Assigned Bus')),
                      DataColumn(label: Text('Valid From')),
                      DataColumn(label: Text('Valid Until')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: assignments.map((a) {
                      return DataRow(cells: [
                        DataCell(Text(a.conductorName.isEmpty ? 'Conductor ID: ${a.conductorId.substring(0, 8)}' : a.conductorName)),
                        DataCell(Text(a.busNumber.isEmpty ? 'Bus ID: ${a.busId.substring(0, 8)}' : a.busNumber)),
                        DataCell(Text('${a.validFrom.year}-${a.validFrom.month.toString().padLeft(2, '0')}-${a.validFrom.day.toString().padLeft(2, '0')}')),
                        DataCell(Text(a.validUntil == null ? 'Permanent / Open' : '${a.validUntil!.year}-${a.validUntil!.month.toString().padLeft(2, '0')}-${a.validUntil!.day.toString().padLeft(2, '0')}')),
                        DataCell(Chip(
                          label: Text(
                            a.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              color: a.isActive ? Colors.green.shade800 : Colors.grey.shade800,
                            ),
                          ),
                          backgroundColor: a.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                          visualDensity: VisualDensity.compact,
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBusDialog(BuildContext context, Bus? bus) {
    final isEdit = bus != null;
    final numController = TextEditingController(text: bus?.busNumber ?? '');
    final descController = TextEditingController(text: bus?.description ?? '');
    bool isActive = bus?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Bus ${bus.busNumber}' : 'Add New Bus'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numController,
                  decoration: const InputDecoration(
                    labelText: 'Bus Number *',
                    hintText: 'e.g. BUS-01',
                  ),
                  enabled: !isEdit,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Route Description / Name',
                    hintText: 'e.g. Central Station - Campus Express',
                  ),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active Status'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final busNum = numController.text.trim();
                if (busNum.isEmpty) return;

                if (isEdit) {
                  await ref.read(busRepositoryProvider).update(bus.id, {
                    'description': descController.text.trim(),
                    'is_active': isActive,
                  });
                } else {
                  await ref.read(busRepositoryProvider).create(
                        busNum,
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                      );
                }
                ref.invalidate(_busesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save Changes' : 'Create Bus'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    final conductorIdController = TextEditingController();
    String? selectedBusId;
    final busesAsync = ref.read(_busesProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Assign Conductor to Bus'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: conductorIdController,
                  decoration: const InputDecoration(
                    labelText: 'Conductor User UUID *',
                    hintText: 'Supabase Auth User ID for conductor',
                  ),
                ),
                const SizedBox(height: 16),
                busesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (buses) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Bus *'),
                    initialValue: selectedBusId,
                    items: buses
                        .where((b) => b.isActive)
                        .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text('${b.busNumber} (${b.description ?? "Active"})'),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedBusId = v),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final conductorId = conductorIdController.text.trim();
                if (conductorId.isEmpty || selectedBusId == null) return;

                await ref.read(busRepositoryProvider).assignConductor(
                      conductorId: conductorId,
                      busId: selectedBusId!,
                      validFrom: DateTime.now(),
                    );
                ref.invalidate(_assignmentsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}
