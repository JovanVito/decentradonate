import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart';
import 'password_reset.dart';

enum AccountMode {
  donor('Donatur'),
  fundraiser('Penggalang Dana');

  const AccountMode(this.label);
  final String label;
}

Future<AccountMode> loadAccountMode() async {
  final settings = await sb.from('mobile_profile_settings').select('mode').maybeSingle();
  return settings?['mode'] == 'fundraiser' ? AccountMode.fundraiser : AccountMode.donor;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.onModeChanged});

  final ValueChanged<AccountMode> onModeChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  late final user = sb.auth.currentUser!;
  late Future<void> loading = load();
  AccountMode mode = AccountMode.donor;
  String? avatarUrl;
  Uint8List? preview;
  bool saving = false;
  bool photoBusy = false;

  String get avatarPath => '${user.id}/avatar';
  StorageFileApi get avatars => sb.storage.from('mobile-avatars');

  Future<void> load() async {
    final results = await Future.wait<Object?>([
      sb.from('mobile_profiles').select('name').eq('id', user.id).single(),
      sb.from('mobile_profile_settings').select('phone, mode').maybeSingle(),
      avatars.list(path: user.id),
    ]);
    final profile = results[0] as Map<String, dynamic>;
    final settings = results[1] as Map<String, dynamic>?;
    final files = results[2] as List<FileObject>;
    final url = files.any((file) => file.name == 'avatar')
        ? await avatars.createSignedUrl(avatarPath, 900)
        : null;
    if (!mounted) return;
    name.text = profile['name'] as String? ?? '';
    phone.text = settings?['phone'] as String? ?? '';
    mode = settings?['mode'] == 'fundraiser' ? AccountMode.fundraiser : AccountMode.donor;
    avatarUrl = url;
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await sb.rpc('mobile_save_profile', params: {
        'p_name': name.text.trim(),
        'p_phone': normalizedPhone,
        'p_mode': mode.name,
      });
      if (!mounted) return;
      widget.onModeChanged(mode);
      toast(context, 'Profil tersimpan.');
    } catch (_) {
      if (mounted) toast(context, 'Profil gagal disimpan. Periksa koneksi dan coba lagi.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String get normalizedPhone => phone.text.trim().replaceAll(RegExp(r'[\s()-]'), '');

  Future<void> changePhoto({required bool remove}) async {
    if (photoBusy) return;
    setState(() => photoBusy = true);
    try {
      if (remove) {
        await avatars.remove([avatarPath]);
        if (mounted) {
          setState(() {
            avatarUrl = null;
            preview = null;
          });
        }
      } else {
        final image = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85,
        );
        if (image == null || !mounted) return;
        final bytes = await image.readAsBytes();
        final mime = switch (image.name.toLowerCase().split('.').last) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => null,
        };
        if (!mounted) return;
        if (mime == null || bytes.length > 5 * 1024 * 1024) {
          toast(context, 'Pilih foto JPG, PNG, atau WebP berukuran maksimal 5 MB.');
          return;
        }
        await avatars.uploadBinary(
          avatarPath,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mime, cacheControl: '0'),
        );
        if (mounted) setState(() => preview = bytes);
      }
    } catch (_) {
      if (mounted) toast(context, 'Foto gagal diperbarui. Periksa koneksi dan coba lagi.');
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil')),
    body: FutureBuilder<void>(
      future: loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) return LoadError(onRetry: () => setState(() => loading = load()));
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final ImageProvider? photo;
        if (preview != null) {
          photo = MemoryImage(preview!);
        } else if (avatarUrl != null) {
          photo = NetworkImage(avatarUrl!);
        } else {
          photo = null;
        }
        return Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: CircleAvatar(
                radius: 45, foregroundImage: photo, child: const Icon(Icons.person, size: 40),
              )),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: photoBusy ? null : () => changePhoto(remove: false),
                    child: Text(photoBusy ? 'Memperbarui foto…' : 'Ubah foto'),
                  ),
                  if (photo != null)
                    TextButton(onPressed: photoBusy ? null : () => changePhoto(remove: true),
                      child: const Text('Hapus foto')),
                ],
              ),
              TextFormField(
                controller: name, maxLength: 80, enabled: !saving,
                decoration: const InputDecoration(labelText: 'Nama', helperText: 'Kosongkan untuk menghapus nama.'),
              ),
              TextFormField(
                initialValue: user.email ?? '', readOnly: true,
                decoration: const InputDecoration(labelText: 'Email terdaftar'),
              ),
              TextFormField(
                controller: phone, keyboardType: TextInputType.phone, enabled: !saving,
                decoration: const InputDecoration(labelText: 'Nomor HP', helperText: 'Kosongkan untuk menghapus nomor.'),
                validator: (_) => normalizedPhone.isNotEmpty &&
                    !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalizedPhone)
                    ? 'Masukkan 7 sampai 15 digit nomor HP.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountMode>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'Mode akun'),
                items: [
                  for (final option in AccountMode.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: saving ? null : (option) => setState(() => mode = option!),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Menyimpan…' : 'Simpan profil')),
              if (user.email != null)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => PasswordResetRequestPage(email: user.email, emailLocked: true),
                  )),
                  child: const Text('Reset kata sandi'),
                ),
            ],
          ),
        );
      },
    ),
  );
}
