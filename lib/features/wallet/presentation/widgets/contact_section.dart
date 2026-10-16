import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/wallet_contact.dart';
import '../providers/contact_providers.dart';

/// CRUD Kontak Wallet — bukti Local Data & Persistence (SQLite).
///
/// Alur: UI (widget ini) -> contactProvider (AsyncNotifier) ->
/// ContactRepositoryImpl (query SQL) -> DatabaseService (file .db di disk).
class ContactSection extends ConsumerWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kontak Wallet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            TextButton.icon(
              onPressed: () => _openForm(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        contacts.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paperDeep.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Belum ada kontak. Tambahkan kontak wallet untuk menyimpan alamat favorit.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              );
            }
            return Column(
              children: [
                for (final contact in list)
                  _ContactTile(contact: contact, ref: ref),
              ],
            );
          },
        ),
      ],
    );
  }

  static Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    WalletContact? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ContactForm(existing: existing),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final WalletContact contact;
  final WidgetRef ref;

  const _ContactTile({required this.contact, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.paperDeep,
            child: Icon(Icons.person_outline, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(
                  '${contact.address.substring(0, contact.address.length.clamp(0, 10))}…',
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Ubah nama',
            onPressed: () =>
                ContactSection._openForm(context, ref, existing: contact),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.error),
            tooltip: 'Hapus',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kontak?'),
        content: Text('Kontak "${contact.name}" akan dihapus dari perangkat.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(ctx);
              Navigator.pop(ctx);
              final error = await ref
                  .read(contactProvider.notifier)
                  .removeContact(contact.id!);
              messenger.showSnackBar(SnackBar(
                content: Text(error ?? 'Kontak dihapus'),
              ));
            },
            child:
                const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ContactForm extends ConsumerStatefulWidget {
  final WalletContact? existing;

  const _ContactForm({this.existing});

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _address = TextEditingController(text: widget.existing?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final notifier = ref.read(contactProvider.notifier);
    final String? error;
    if (widget.existing == null) {
      error = await notifier.addContact(
        name: _name.text,
        address: _address.text,
      );
    } else {
      error = await notifier.editContact(widget.existing!.copyWith(
        name: _name.text.trim(),
        address: _address.text.trim(),
      ));
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Kontak tersimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Ubah Kontak' : 'Tambah Kontak',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama kontak'),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Nama minimal 2 karakter'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              enabled: !isEdit,
              decoration:
                  const InputDecoration(labelText: 'Alamat wallet (0x…)'),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (!RegExp(r'^0x[0-9a-fA-F]{6,}$').hasMatch(value)) {
                  return 'Alamat harus diawali 0x dan berupa hex';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: isEdit ? 'Simpan Perubahan' : 'Simpan Kontak',
              icon: Icons.save_outlined,
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
