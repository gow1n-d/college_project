import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/conductor.dart';
import 'conductors_provider.dart';

class ConductorsPage extends ConsumerStatefulWidget {
  const ConductorsPage({super.key});

  @override
  ConsumerState<ConductorsPage> createState() => _ConductorsPageState();
}

class _ConductorsPageState extends ConsumerState<ConductorsPage> {
  String _searchQuery = '';
  final Set<String> _revealedPasswords = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conductorsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Conductor Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(conductorsProvider.notifier).refresh(),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add Conductor'),
            onPressed: () => _showAddConductorDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informative banner explaining dynamic bus numbers
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF1E40AF)),
                          children: const [
                            TextSpan(
                              text: 'Dynamic Bus Assignment: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Bus numbers change randomly per route/day. Conductors log into the mobile app with their static username & password, and directly enter whichever bus number they are operating today.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search bar
              Container(
                width: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or username...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(height: 16),

              // Table / List
              Expanded(
                child: state.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                  ),
                  data: (conductors) {
                    final filtered = conductors.where((c) {
                      if (_searchQuery.isEmpty) return true;
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          c.username.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'No conductors found' : 'No conductors matching search',
                              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      );
                    }

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                              dataRowMinHeight: 64,
                              dataRowMaxHeight: 68,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columnSpacing: 28,
                              horizontalMargin: 20,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Conductor',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Username',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Password',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                ),
                              ],
                              rows: filtered.map((c) {
                                final isPasswordRevealed = _revealedPasswords.contains(c.id);

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: const Color(0xFFEEF2FF),
                                              child: Text(
                                                c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF4F46E5),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  c.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                if (c.phone != null && c.phone!.isNotEmpty)
                                                  Text(
                                                    c.phone!,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              c.username,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.copy, size: 16, color: Color(0xFF94A3B8)),
                                            tooltip: 'Copy username',
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: c.username));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Username "${c.username}" copied!')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isPasswordRevealed ? c.password : '••••••••',
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: Icon(
                                              isPasswordRevealed ? Icons.visibility_off : Icons.visibility,
                                              size: 16,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                            tooltip: isPasswordRevealed ? 'Hide' : 'Show password',
                                            onPressed: () {
                                              setState(() {
                                                if (isPasswordRevealed) {
                                                  _revealedPasswords.remove(c.id);
                                                } else {
                                                  _revealedPasswords.add(c.id);
                                                }
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy, size: 16, color: Color(0xFF94A3B8)),
                                            tooltip: 'Copy password',
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: c.password));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Password copied!')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: c.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          c.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: c.isActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                        tooltip: 'Remove Conductor',
                                        onPressed: () => _confirmDelete(context, c),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              ),
                            ),
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

  void _showAddConductorDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'conductor123');
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Conductor'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conductors have static credentials to log into the mobile app and specify their bus number on duty.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Ramesh Kumar',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Static Username *',
                      hintText: 'e.g. conductor1',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().contains(' ')) return 'No spaces allowed';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Static Password *',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      hintText: 'e.g. 9876543210',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(dialogCtx).pop();

              try {
                await ref.read(conductorsProvider.notifier).addConductor(
                      name: nameCtrl.text,
                      username: usernameCtrl.text,
                      password: passwordCtrl.text,
                      phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Conductor "${nameCtrl.text}" added successfully!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
                  );
                }
              }
            },
            child: const Text('Add Conductor'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Conductor conductor) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Conductor'),
        content: Text(
          'Are you sure you want to remove conductor "${conductor.name}" (${conductor.username})? They will no longer be able to log into the mobile app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await ref.read(conductorsProvider.notifier).removeConductor(conductor.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Conductor "${conductor.name}" removed.'),
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
