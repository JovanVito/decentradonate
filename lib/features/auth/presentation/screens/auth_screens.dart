import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  String get label {
    if (password.length < 8) return 'Weak';
    final score = [
      password.contains(RegExp(r'[A-Z]')),
      password.contains(RegExp(r'[a-z]')),
      password.contains(RegExp(r'[0-9]')),
      password.contains(RegExp(r'[^A-Za-z0-9]')),
    ].where((value) => value).length;
    return score >= 3 ? 'Strong' : 'Medium';
  }

  Color get color => label == 'Strong'
      ? Colors.green
      : label == 'Medium'
          ? Colors.orange
          : Colors.red;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Text('Kekuatan password: $label', style: TextStyle(color: color)),
    );
  }
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose(); _email.dispose(); _password.dispose(); _confirm.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final result = await ref.read(authRepositoryProvider).signUp(
      username: _username.text.trim(), email: _email.text.trim(), password: _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold((failure) => _message(failure.message), (_) => _message('Signup berhasil. Cek email untuk verifikasi.'));
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buat Akun')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username'), validator: (v) => v == null || v.trim().length < 3 ? 'Username minimal 3 karakter' : null),
      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null),
      TextFormField(controller: _password, obscureText: true, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Password'), validator: (v) => v == null || v.length < 8 ? 'Password minimal 8 karakter' : null),
      PasswordStrengthMeter(password: _password.text),
      TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi Password'), validator: (v) => v != _password.text ? 'Password tidak sama' : null),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text('Daftar')),
    ])),
  );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(); final _password = TextEditingController(); bool _loading = false;
  Future<void> _login() async {
    setState(() => _loading = true);
    final result = await ref.read(authRepositoryProvider).signIn(email: _email.text.trim(), password: _password.text);
    if (!mounted) return; setState(() => _loading = false);
    result.fold((failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))), (_) => context.go('/'));
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Login')), body: ListView(padding: const EdgeInsets.all(20), children: [
    TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
    TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())), child: const Text('Forgot password?'))),
    ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? const CircularProgressIndicator() : const Text('Masuk')),
    TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text('Buat akun')),
  ]));
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController(); bool _sent = false;
  Future<void> _send() async { final result = await ref.read(authRepositoryProvider).sendPasswordReset(_email.text.trim()); if (!mounted) return; result.fold((failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))), (_) => setState(() => _sent = true)); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Reset Password')), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')), const SizedBox(height: 16), ElevatedButton(onPressed: _send, child: const Text('Kirim Link Reset')), if (_sent) const Text('Link reset telah dikirim ke email.')])));
}
