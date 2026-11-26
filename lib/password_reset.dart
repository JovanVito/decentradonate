import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart';

class PasswordResetRequestPage extends StatefulWidget {
  const PasswordResetRequestPage({super.key, this.email, this.emailLocked = false});

  final String? email;
  final bool emailLocked;

  @override
  State<PasswordResetRequestPage> createState() => _PasswordResetRequestPageState();
}

class _PasswordResetRequestPageState extends State<PasswordResetRequestPage> {
  final form = GlobalKey<FormState>();
  late final email = TextEditingController(text: widget.email);
  bool busy = false;
  bool sent = false;

  Future<void> send() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await sb.auth.resetPasswordForEmail(email.text.trim(), redirectTo: emailConfirmationUrl);
      if (mounted) setState(() => sent = true);
    } catch (_) {
      if (mounted) toast(context, 'Tautan gagal dikirim. Tunggu sebentar, lalu coba lagi.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset kata sandi')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: email,
            readOnly: widget.emailLocked || busy || sent,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email terdaftar'),
            validator: (value) => !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
                ? 'Masukkan alamat email yang valid.' : null,
          ),
          const SizedBox(height: 16),
          if (sent)
            const Text('Jika email terdaftar, tautan reset akan dikirim. Buka tautan di ponsel ini.'),
          if (!sent)
            FilledButton(onPressed: busy ? null : send, child: const Text('Kirim tautan reset')),
        ],
      ),
    ),
  );
}

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final form = GlobalKey<FormState>();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await sb.auth.updateUser(UserAttributes(password: password.text));
      if (!mounted) return;
      toast(context, 'Kata sandi baru tersimpan.');
      widget.onComplete();
    } on AuthException catch (error) {
      if (mounted) toast(context, error.message);
    } catch (_) {
      if (mounted) toast(context, 'Kata sandi gagal disimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buat kata sandi baru')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: password, obscureText: true, enabled: !busy,
            decoration: const InputDecoration(labelText: 'Kata sandi baru'),
            validator: (value) => value!.length < 8 ? 'Gunakan minimal 8 karakter.' : null,
          ),
          TextFormField(
            controller: confirmation, obscureText: true, enabled: !busy,
            decoration: const InputDecoration(labelText: 'Ulangi kata sandi'),
            validator: (value) => value != password.text ? 'Kedua kata sandi harus sama.' : null,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: busy ? null : save, child: const Text('Simpan kata sandi')),
          TextButton(onPressed: busy ? null : () => sb.auth.signOut(), child: const Text('Batal dan keluar')),
        ],
      ),
    ),
  );
}
