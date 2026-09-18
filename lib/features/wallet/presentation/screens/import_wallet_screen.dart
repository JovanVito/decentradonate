import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/wallet_providers.dart';

/// Form import wallet dari 12 kata yang sudah dipunyai user.
/// `ConsumerStatefulWidget` dipakai karena butuh `TextEditingController`
/// (butuh State lifecycle) SEKALIGUS akses provider (`ref`).
class ImportWalletScreen extends ConsumerStatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  ConsumerState<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends ConsumerState<ImportWalletScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final success = await ref.read(walletProvider.notifier).importWallet(_controller.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      context.go('/wallet');
    } else {
      final err = ref.read(walletProvider).error;
      setState(() => _errorText = err?.toString() ?? 'Gagal mengimpor wallet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan 12 kata seed phrase, dipisah spasi.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'contoh: apple banana cherry ...',
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Import', isLoading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
