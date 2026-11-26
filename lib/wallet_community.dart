import 'package:flutter/material.dart';
import 'main.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Future<List<dynamic>> f = _load();
  Future<List<dynamic>> _load() => Future.wait([
        sb.from('profiles').select().eq('id', sb.auth.currentUser!.id).single(),
        sb.from('topups').select().order('created_at', ascending: false).limit(10),
        sb.from('donations').select('amount, created_at, campaigns(title)').eq('donor_id', sb.auth.currentUser!.id).order('created_at', ascending: false).limit(10),
      ]);

  Future<void> topup(int amt) async {
    try {
      await sb.rpc('topup', params: {'p_amount': amt}); // DEMO: ganti dengan payment gateway
      setState(() => f = _load());
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
        future: f,
        builder: (_, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final p = s.data![0] as Map, tops = s.data![1] as List, dons = s.data![2] as List;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: ListTile(title: const Text('Saldo'), subtitle: Text(rp(p['balance']), style: Theme.of(context).textTheme.headlineSmall))),
            Wrap(spacing: 8, children: [for (final a in [10000, 50000, 100000, 500000]) ActionChip(label: Text('Top up ${rp(a)}'), onPressed: () => topup(a))]),
            const Divider(height: 32),
            const Text('Riwayat Top Up', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final t in tops) ListTile(dense: true, leading: const Icon(Icons.add_circle, color: Colors.green), title: Text(rp(t['amount'])), subtitle: Text('${t['created_at']}'.substring(0, 16))),
            const Text('Riwayat Donasi', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final d in dons) ListTile(dense: true, leading: const Icon(Icons.favorite, color: Colors.red), title: Text(rp(d['amount'])), subtitle: Text('${d['campaigns']?['title']}')),
          ]);
        },
      );
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final ctrl = TextEditingController();
  late Future<List<dynamic>> f = _load();
  Future<List<dynamic>> _load() => sb.from('posts').select('*, profiles(name)').order('created_at', ascending: false).limit(50);

  Future<void> send() async {
    if (ctrl.text.trim().isEmpty) return;
    await sb.from('posts').insert({'user_id': sb.auth.currentUser!.id, 'content': ctrl.text.trim()});
    ctrl.clear();
    setState(() => f = _load());
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() => f = _load()),
            child: FutureBuilder<List<dynamic>>(
              future: f,
              builder: (_, s) => !s.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(children: [for (final p in s.data!) ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(p['profiles']?['name'] ?? 'Anonim'), subtitle: Text(p['content']))]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Tulis sesuatu...', border: OutlineInputBorder()))),
            IconButton(icon: const Icon(Icons.send), onPressed: send),
          ]),
        ),
      ]);
}
