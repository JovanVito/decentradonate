import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'campaign.dart';
import 'wallet_community.dart';
import 'local_notes.dart';
import 'password_reset.dart';
import 'profile.dart';
final sb = Supabase.instance.client;
String rp(num n) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(n);
void toast(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const emailConfirmationUrl = 'com.donasitransparan.mobile://auth-callback';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError('SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY wajib diisi dengan --dart-define');
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(MaterialApp(
    title: 'Donasi Transparan',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: const AuthGate(),
  ));
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> subscription;
  bool recovering = false;

  @override
  void initState() {
    super.initState();
    subscription = sb.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      final recovery = state.event == AuthChangeEvent.passwordRecovery;
      final signedOut = state.event == AuthChangeEvent.signedOut;
      setState(() {
        if (recovery) recovering = true;
        if (signedOut) recovering = false;
      });
      if (recovery || signedOut) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        });
      }
    }, onError: (Object error) {
      if (mounted) toast(context, 'Tautan tidak dapat digunakan. Minta tautan baru jika sudah kedaluwarsa.');
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = sb.auth.currentUser;
    if (user == null) return const AuthPage();
    if (recovering) {
      return PasswordRecoveryPage(onComplete: () => setState(() => recovering = false));
    }
    return Home(key: ValueKey(user.id));
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(), pass = TextEditingController(), name = TextEditingController();
  bool signup = false, busy = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      if (signup) {
        final response = await sb.auth.signUp(
          email: email.text.trim(),
          password: pass.text,
          emailRedirectTo: emailConfirmationUrl,
          data: {'name': name.text.trim()},
        );
        if (mounted && response.session == null) {
          setState(() => signup = false);
          toast(context, 'Buka tautan konfirmasi dari email di ponsel ini.');
        }
      } else {
        await sb.auth.signInWithPassword(email: email.text.trim(), password: pass.text);
      }
    } on AuthException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) toast(context, 'Gagal terhubung. Coba lagi.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Icon(Icons.volunteer_activism, size: 72, color: Colors.teal),
              Text('Donasi Transparan', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              if (signup) TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              FilledButton(onPressed: busy ? null : submit, child: Text(signup ? 'Daftar' : 'Masuk')),
              TextButton(onPressed: () => setState(() => signup = !signup), child: Text(signup ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar')),
              if (!signup)
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => PasswordResetRequestPage(email: email.text.trim()),
                  )),
                  child: const Text('Lupa kata sandi?'),
                ),
            ]),
          ),
        ),
      );
}

class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: onRetry,
      child: const Text('Gagal memuat data. Coba lagi'),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int i = 0;
  int? donationCount;
  int countRequest = 0;
  AccountMode mode = AccountMode.donor;

  @override
  void initState() {
    super.initState();
    refreshMode();
    refreshDonationCount();
  }

  Future<void> refreshDonationCount() async {
    final request = ++countRequest;
    try {
      final count = await sb.from('mobile_donations').count(CountOption.exact)
          .eq('donor_id', sb.auth.currentUser!.id);
      if (mounted && request == countRequest) setState(() => donationCount = count);
    } catch (_) {
      // Keep the last known count when the network is unavailable.
    }
  }

  void donationAdded() {
    if (!mounted) return;
    setState(() => donationCount = (donationCount ?? 0) + 1);
    refreshDonationCount();
  }

  Future<void> refreshMode() async {
    try {
      final savedMode = await loadAccountMode();
      if (mounted) setState(() => mode = savedMode);
    } catch (_) {
      if (mounted) toast(context, 'Mode akun gagal dimuat. Buka Profil untuk mencoba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(i == 1 ? 'Forum' : 'Donasi Transparan'),
          actions: [
            IconButton(
              tooltip: 'Riwayat donasi',
              icon: Badge(
                isLabelVisible: donationCount != null,
                label: Text('${donationCount ?? 0}'),
                child: const Icon(Icons.favorite, color: Colors.pink),
              ),
              onPressed: () {
                setState(() => i = 2);
                refreshDonationCount();
              },
            ),
            IconButton(
              tooltip: 'Profil (${mode.label})',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ProfilePage(onModeChanged: (updated) => setState(() => mode = updated)),
              )),
            ),
            IconButton(tooltip: 'Keluar', icon: const Icon(Icons.logout), onPressed: () => sb.auth.signOut()),
          ],
        ),
        body: [
          CampaignList(fundraising: mode == AccountMode.fundraiser, onDonation: donationAdded),
          const CommunityPage(),
          const WalletPage(),
          const LocalNotesPage(),
        ][i],
        bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: const [
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Campaign'),
          NavigationDestination(icon: Icon(Icons.forum), label: 'Komunitas'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Dompet'),
          NavigationDestination(icon: Icon(Icons.note_alt), label: 'Catatan'),
        ]),
      );
}
