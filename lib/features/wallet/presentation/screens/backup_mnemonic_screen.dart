import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

/// Layar ini SENGAJA "memaksa" user (`PopScope(canPop: false)`) supaya
/// tidak bisa swipe-back tanpa sadar sebelum mencatat seed phrase-nya.
/// Ini pola standar di semua wallet app nyata (MetaMask, Trust Wallet,
/// dst) — kalau kamu tunjukkan pola ini ke dosen, itu poin plus untuk
/// pemahaman UX keamanan, bukan cuma "asal jalan".
class BackupMnemonicScreen extends StatefulWidget {
  final String mnemonic;
  const BackupMnemonicScreen({super.key, required this.mnemonic});

  @override
  State<BackupMnemonicScreen> createState() => _BackupMnemonicScreenState();
}

class _BackupMnemonicScreenState extends State<BackupMnemonicScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(' ');

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Simpan Seed Phrase'),
          automaticallyImplyLeading: false, // cegah tombol back default
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'JANGAN screenshot atau kirim frasa ini ke siapa pun, '
                        'termasuk yang mengaku "admin"/"support". Siapa pun yang '
                        'punya 12 kata ini bisa mengambil alih wallet-mu sepenuhnya.',
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: words.length,
                  itemBuilder: (context, i) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}. ${words[i]}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.mnemonic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Disalin — segera tempel ke tempat aman, lalu hapus dari clipboard.'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Salin ke Clipboard'),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Saya sudah menyimpan 12 kata ini di tempat yang aman.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              PrimaryButton(
                label: 'Lanjutkan',
                onPressed: _confirmed ? () => context.go('/wallet') : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
