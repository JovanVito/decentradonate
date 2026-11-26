import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'campaign.dart';
import 'wallet_community.dart';
import 'local_notes.dart';
final sb = Supabase.instance.client;
String rp(num n) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(n);
void toast(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError('SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY wajib diisi dengan --dart-define');
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(MaterialApp(
    title: 'Donasi Transparan',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: StreamBuilder(
      stream: sb.auth.onAuthStateChange,
      builder: (_, __) => sb.auth.currentSession == null ? const AuthPage() : const Home(),
    ),
  ));
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(), pass = TextEditingController(), name = TextEditingController();
  bool signup = false, busy = false;

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      if (signup) {
        await sb.auth.signUp(email: email.text.trim(), password: pass.text, data: {'name': name.text.trim()});
        if (mounted) toast(context, 'Berhasil daftar. Cek email jika verifikasi aktif.');
      } else {
        await sb.auth.signInWithPassword(email: email.text.trim(), password: pass.text);
      }
    } on AuthException catch (e) {
      if (mounted) toast(context, e.message);
    }
    if (mounted) setState(() => busy = false);
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
            ]),
          ),
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
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Donasi Transparan'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => sb.auth.signOut())]),
        body: [const CampaignList(), const CommunityPage(), const WalletPage(), const LocalNotesPage()][i],
        bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: const [
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Campaign'),
          NavigationDestination(icon: Icon(Icons.forum), label: 'Komunitas'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Dompet'),
          NavigationDestination(icon: Icon(Icons.note_alt), label: 'Catatan'),
        ]),
      );
}
