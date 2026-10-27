import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../data/auth_repository.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _loading = false;

  // Rate limiting: max 5 attempts per 2 minutes
  int _attempts = 0;
  DateTime? _lockedUntil;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)) {
      setState(() => _error = 'Too many attempts. Try again in a moment.');
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Password is required');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final profile = await ref.read(authRepositoryProvider).signInAdmin(password);
      ref.read(adminLoggedInProvider.notifier).state = true;
      ref.read(currentAdminProfileProvider.notifier).state = profile;
      _attempts = 0;
      if (mounted) context.go('/admin/dashboard');
    } catch (e) {
      _attempts++;
      if (_attempts >= 5) {
        _lockedUntil = DateTime.now().add(const Duration(minutes: 2));
        _attempts = 0;
      }
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('AppAuthException: ', '');
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.directions_bus_rounded,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Admin Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center),
                  Text('College Bus Attendance System',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
