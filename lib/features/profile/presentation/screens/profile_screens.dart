import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (user) => ListView(padding: const EdgeInsets.all(20), children: [
          const CircleAvatar(radius: 44, child: Icon(Icons.person, size: 44)),
          const SizedBox(height: 16),
          Text(user.username, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          Text(user.email, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ListTile(leading: const Icon(Icons.phone), title: Text(user.phone ?? 'Nomor handphone belum diisi')),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Pengaturan'), onTap: () => context.push('/settings')),
          if (!user.isOrganizer) ListTile(leading: const Icon(Icons.campaign), title: const Text('Menjadi Penyelenggara'), onTap: () => context.push('/organizer/terms')),
          if (user.isOrganizer) ListTile(leading: const Icon(Icons.add), title: const Text('Buat Campaign'), onTap: () => context.push('/campaign/create')),
        ]),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('Pengaturan')), body: ListView(padding: const EdgeInsets.all(20), children: [
    ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () async { await ref.read(authRepositoryProvider).signOut(); if (context.mounted) context.go('/login'); }),
    ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('Hapus Akun', style: TextStyle(color: Colors.red)),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hapus akun?'),
          content: const Text('Data akun akan dihapus sesuai kebijakan server.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await ref.read(authRepositoryProvider).deleteAccount();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.fold((f) => f.message, (_) => 'Akun dihapus'))),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
    ),
  ]));
}

class OrganizerTermsScreen extends ConsumerStatefulWidget {
  const OrganizerTermsScreen({super.key});
  @override ConsumerState<OrganizerTermsScreen> createState() => _OrganizerTermsScreenState();
}
class _OrganizerTermsScreenState extends ConsumerState<OrganizerTermsScreen> {
  final _checked = <bool>[false, false, false, false];
  final _terms = const ['Informasi campaign harus benar dan dapat dipertanggungjawabkan.', 'Dana hanya digunakan sesuai tujuan campaign.', 'Bukti penggunaan dana wajib diunggah setelah penyaluran.', 'Penyelenggara bersedia menerima pemeriksaan dan laporan dari pengguna.'];
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Syarat Penyelenggara')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('Baca dan setujui seluruh ketentuan berikut sebelum membuka campaign.'), ...List.generate(_terms.length, (i) => CheckboxListTile(value: _checked[i], title: Text(_terms[i]), onChanged: (value) => setState(() => _checked[i] = value ?? false))), ElevatedButton(onPressed: _checked.every((value) => value) ? () async { final result = await ref.read(authRepositoryProvider).becomeOrganizer(); if (!context.mounted) return; result.fold((f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))), (_) => context.go('/campaign/create')); } : null, child: const Text('Setuju dan Lanjut'))]));
}

class CreateCampaignScreen extends StatefulWidget { const CreateCampaignScreen({super.key}); @override State<CreateCampaignScreen> createState() => _CreateCampaignScreenState(); }
class _CreateCampaignScreenState extends State<CreateCampaignScreen> { final _formKey = GlobalKey<FormState>(); final _title = TextEditingController(); final _description = TextEditingController(); final _target = TextEditingController(); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Buat Campaign')), body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Judul campaign'), validator: (v) => v == null || v.trim().length < 5 ? 'Judul minimal 5 karakter' : null), TextFormField(controller: _description, maxLines: 4, decoration: const InputDecoration(labelText: 'Deskripsi'), validator: (v) => v == null || v.trim().length < 20 ? 'Deskripsi minimal 20 karakter' : null), TextFormField(controller: _target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target dana MATIC'), validator: (v) => double.tryParse(v ?? '') == null ? 'Target tidak valid' : null), const SizedBox(height: 20), ElevatedButton(onPressed: () { if (_formKey.currentState!.validate()) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form campaign valid dan siap dikirim ke blockchain.'))); }, child: const Text('Lanjutkan'))]))); }
