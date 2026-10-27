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
      ref.read(conductorInfoProvider.notifier).state = null;
      ref.read(adminLoggedInProvider.notifier).state = true;
      ref.read(currentAdminProfileProvider.notifier).state = profile;
      if (mounted) {
        setState(() => _adminLoading = false);
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
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF1565C0);
                            }
                            return const Color(0xFFF1F5F9);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return const Color(0xFF0F172A);
                          }),
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                            ),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: 'conductor',
                            label: Text('Conductor Mode'),
                            icon: Icon(Icons.directions_bus),
                          ),
                          ButtonSegment(
                            value: 'admin',
                            label: Text('Admin Mode'),
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
                      const SizedBox(height: 24),

                      if (_mode == 'conductor') ...[
                        // ── CONDUCTOR LOGIN VIEW ─────────────────────────────
                        Center(
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFDBEAFE),
                            child: const Icon(Icons.directions_bus_rounded,
                                size: 36, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Conductor Duty Login',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your static credentials and your assigned bus number for today',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        Form(
                          key: _conductorFormKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usernameCtrl,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Static Username',
                                  labelStyle: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  hintText: 'e.g. conductor1',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(Icons.person, color: Color(0xFF1E293B)),
                                  fillColor: Colors.white,
                                  filled: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(color: Color(0xFF64748B), width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(color: Color(0xFF1565C0), width: 2.2),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Username required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _busCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Bus Number Today',
                                  labelStyle: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  hintText: 'e.g. BUS-01, V1, K1',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  helperText: 'Enter whichever bus you are operating today',
                                  helperStyle: TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  prefixIcon: Icon(Icons.directions_bus_filled, color: Color(0xFF1E293B)),
                                  fillColor: Colors.white,
                                  filled: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(color: Color(0xFF64748B), width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(color: Color(0xFF1565C0), width: 2.2),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Bus Number required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _conductorPasswordCtrl,
                                obscureText: _obscureConductor,
                                onFieldSubmitted: (_) => _loginConductor(),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Static Password',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  hintText: 'conductor123',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF1E293B)),
                                  fillColor: Colors.white,
                                  filled: true,
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(color: Color(0xFF64748B), width: 1.5),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(color: Color(0xFF1565C0), width: 2.2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConductor
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConductor = !_obscureConductor),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Password required' : null,
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
                              border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                            ),
                            child: Text(
                              conductorState.error!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed:
                              conductorState.loading ? null : _loginConductor,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
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
                              : const Text(
                                  'Start Bus Duty / Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ] else ...[
                        // ── ADMIN LOGIN VIEW ─────────────────────────────────
                        Center(
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: const Icon(Icons.admin_panel_settings_rounded,
                                size: 36, color: Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Administrator Access',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter superadmin password to access dashboard',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Tip box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.vpn_key_rounded, color: Color(0xFF1D4ED8), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Password: superadmin\n(No username or bus number required)',
                                  style: TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Form(
                          key: _adminFormKey,
                          child: TextFormField(
                            controller: _adminPasswordCtrl,
                            obscureText: _obscureAdmin,
                            autofocus: true,
                            onFieldSubmitted: (_) => _loginAdmin(),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Admin Password',
                              labelStyle: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                              ),
                              hintText: 'superadmin',
                              hintStyle: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF1E293B)),
                              fillColor: Colors.white,
                              filled: true,
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Color(0xFF64748B), width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Color(0xFF1565C0), width: 2.2),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureAdmin
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color(0xFF1E293B),
                                ),
                                onPressed: () =>
                                    setState(() => _obscureAdmin = !_obscureAdmin),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Admin password required' : null,
                          ),
                        ),

                        if (_adminError != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                            ),
                            child: Text(
                              _adminError!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed: _adminLoading ? null : _loginAdmin,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
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
                              : const Text(
                                  'Login as Admin',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
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
