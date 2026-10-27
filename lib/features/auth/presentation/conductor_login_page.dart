import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../data/auth_repository.dart';

class ConductorLoginPage extends ConsumerStatefulWidget {
  const ConductorLoginPage({super.key});

  @override
  ConsumerState<ConductorLoginPage> createState() => _ConductorLoginPageState();
}

class _ConductorLoginPageState extends ConsumerState<ConductorLoginPage> {
  // Mode: 'conductor' or 'admin'
  String _mode = 'conductor';

  // Conductor form
  final _conductorFormKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'conductor1');
  final _busCtrl = TextEditingController(text: 'BUS-01');
  final _conductorPasswordCtrl = TextEditingController(text: 'conductor123');
  bool _obscureConductor = true;

  // Admin form
  final _adminFormKey = GlobalKey<FormState>();
  final _adminPasswordCtrl = TextEditingController(text: 'superadmin');
  bool _obscureAdmin = true;
  bool _adminLoading = false;
  String? _adminError;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _busCtrl.dispose();
    _conductorPasswordCtrl.dispose();
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginConductor() async {
    if (!_conductorFormKey.currentState!.validate()) return;
    final ok = await ref.read(conductorLoginProvider.notifier).login(
          username: _usernameCtrl.text.trim(),
          busNumber: _busCtrl.text.trim(),
          password: _conductorPasswordCtrl.text,
        );
    if (ok && mounted) {
      final info = ref.read(conductorLoginProvider).conductor!;
      ref.read(conductorInfoProvider.notifier).state = info;
      context.go('/home');
    }
  }

  Future<void> _loginAdmin() async {
    if (!_adminFormKey.currentState!.validate()) return;
    setState(() {
      _adminLoading = true;
      _adminError = null;
    });

    try {
      final password = _adminPasswordCtrl.text.trim();
      final profile = await ref.read(authRepositoryProvider).signInAdmin(password);
      ref.read(adminLoggedInProvider.notifier).state = true;
      ref.read(currentAdminProfileProvider.notifier).state = profile;
      if (mounted) {
        context.go('/admin/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adminError = e.toString().replaceAll('Exception: ', '');
          _adminLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conductorState = ref.watch(conductorLoginProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 3,
                shadowColor: Colors.black12,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role Selector Tabs (Conductor vs Admin)
                      SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: theme.colorScheme.primary,
                          selectedForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: 'conductor',
                            label: Text('Conductor'),
                            icon: Icon(Icons.directions_bus),
                          ),
                          ButtonSegment(
                            value: 'admin',
                            label: Text('Admin'),
                            icon: Icon(Icons.admin_panel_settings),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (set) {
                          setState(() {
                            _mode = set.first;
                            _adminError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 28),

                      if (_mode == 'conductor') ...[
                        // ── CONDUCTOR LOGIN VIEW ─────────────────────────────
                        Center(
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.directions_bus_rounded,
                                size: 36, color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Conductor Duty Login',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your static credentials and your assigned bus number for today',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        Form(
                          key: _conductorFormKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usernameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Static Username',
                                  hintText: 'e.g. conductor1',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _busCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Bus Number Today',
                                  hintText: 'e.g. BUS-01, V1, K1',
                                  helperText: 'Enter whichever bus you are operating',
                                  prefixIcon: Icon(Icons.directions_bus_outlined),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _conductorPasswordCtrl,
                                obscureText: _obscureConductor,
                                onFieldSubmitted: (_) => _loginConductor(),
                                decoration: InputDecoration(
                                  labelText: 'Static Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConductor
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(() =>
                                        _obscureConductor = !_obscureConductor),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),

                        if (conductorState.error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              conductorState.error!,
                              style: const TextStyle(
                                  color: Color(0xFFDC2626), fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed:
                              conductorState.loading ? null : _loginConductor,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: conductorState.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Start Bus Duty / Login',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ] else ...[
                        // ── ADMIN LOGIN VIEW ─────────────────────────────────
                        // (Only password field — superadmin — no username or bus required!)
                        Center(
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: const Icon(Icons.admin_panel_settings_rounded,
                                size: 36, color: Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Administrator Access',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter superadmin password to access dashboard',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        Form(
                          key: _adminFormKey,
                          child: TextFormField(
                            controller: _adminPasswordCtrl,
                            obscureText: _obscureAdmin,
                            autofocus: true,
                            onFieldSubmitted: (_) => _loginAdmin(),
                            decoration: InputDecoration(
                              labelText: 'Admin Password',
                              hintText: 'superadmin',
                              prefixIcon: const Icon(Icons.key_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureAdmin
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () =>
                                    setState(() => _obscureAdmin = !_obscureAdmin),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),

                        if (_adminError != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              _adminError!,
                              style: const TextStyle(
                                  color: Color(0xFFDC2626), fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        FilledButton(
                          onPressed: _adminLoading ? null : _loginAdmin,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _adminLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Login as Admin',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
