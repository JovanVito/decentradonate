import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'forum_conversations.dart';
import 'main.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int donationLimit = 10;
  late Future<List<dynamic>> f = _load();
  Future<List<dynamic>> _load() => Future.wait([
        sb.rpc('mobile_balance'),
        sb.from('mobile_topups').select().order('created_at', ascending: false).limit(10),
        sb.from('mobile_donations').select('amount, created_at, campaigns:mobile_campaigns(title)').eq('donor_id', sb.auth.currentUser!.id).order('created_at', ascending: false).order('id', ascending: false).limit(donationLimit + 1),
      ]);

  Future<void> topup(int amount) async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => TopupMethodPage(amount: amount),
    ));
    if (mounted && added == true) {
      setState(() => f = _load());
      toast(context, 'Saldo aplikasi bertambah ${rp(amount)}.');
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
        future: f,
        builder: (_, s) {
          if (s.hasError) return LoadError(onRetry: () => setState(() => f = _load()));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final balance = s.data![0] as num, tops = s.data![1] as List, dons = s.data![2] as List;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: ListTile(title: const Text('Saldo aplikasi'), subtitle: Text(rp(balance), style: Theme.of(context).textTheme.headlineSmall))),
            const ListTile(
              leading: Icon(Icons.favorite, color: Colors.pink),
              title: Text('Riwayat donasi'),
            ),
            if (dons.isEmpty) const ListTile(title: Text('Belum ada donasi.')),
            for (final d in dons.take(donationLimit))
              ListTile(
                dense: true,
                leading: const Icon(Icons.favorite, color: Colors.pink),
                title: Text(rp(d['amount'])),
                subtitle: Text(d['campaigns']?['title'] as String? ?? 'Campaign'),
                trailing: Text(DateFormat('dd/MM/yy').format(DateTime.parse(d['created_at'] as String).toLocal())),
              ),
            if (dons.length > donationLimit)
              TextButton(
                onPressed: () => setState(() {
                  donationLimit += 10;
                  f = _load();
                }),
                child: const Text('Lihat donasi lainnya'),
              ),
            const Divider(height: 32),
            Wrap(spacing: 8, children: [for (final a in [10000, 50000, 100000, 500000]) ActionChip(label: Text('Top up ${rp(a)}'), onPressed: () => topup(a))]),
            const Divider(height: 32),
            const Text('Riwayat Top Up', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final t in tops) ListTile(dense: true, leading: const Icon(Icons.add_circle, color: Colors.green), title: Text(rp(t['amount'])), subtitle: Text('${t['created_at']}'.substring(0, 16))),
          ]);
        },
      );
}

enum TopupMethod {
  qris('QRIS', Icons.qr_code_2),
  bank('Transfer bank', Icons.account_balance),
  wallet('E-wallet', Icons.account_balance_wallet);

  const TopupMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

class TopupMethodPage extends StatefulWidget {
  const TopupMethodPage({super.key, required this.amount});

  final int amount;

  @override
  State<TopupMethodPage> createState() => _TopupMethodPageState();
}

class _TopupMethodPageState extends State<TopupMethodPage> {
  TopupMethod? method;
  bool submitting = false;
  String? error;

  Future<void> confirm() async {
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      await sb.rpc('mobile_demo_topup', params: {'p_amount': widget.amount});
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        submitting = false;
        error = 'Saldo gagal ditambah. Periksa koneksi dan batas saldo Rp1.000.000.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !submitting,
    child: Scaffold(
      appBar: AppBar(title: const Text('Metode top up')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(rp(widget.amount), style: Theme.of(context).textTheme.headlineMedium),
          const Text('Saldo berlaku di aplikasi. Pilihan metode ini tidak memproses pembayaran.'),
          const SizedBox(height: 16),
          for (final option in TopupMethod.values)
            Card(
              child: ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                selected: method == option,
                trailing: method == option ? const Icon(Icons.check_circle) : null,
                onTap: submitting ? null : () => setState(() => method = option),
              ),
            ),
          const SizedBox(height: 16),
          if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          FilledButton(
            onPressed: method == null || submitting ? null : confirm,
            child: Text(submitting ? 'Menambah saldo…' : 'Tambah saldo'),
          ),
        ],
      ),
    ),
  );
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, this.loadPosts});

  final Future<List<dynamic>> Function()? loadPosts;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

typedef _ForumEntry = ({String author, String text, DateTime time, bool own});

class _CommunityPageState extends State<CommunityPage> {
  static const interval = Duration(seconds: 6);
  static const conversationWindow = 40;

  final ctrl = TextEditingController();
  final conversation = <_ForumEntry>[];
  late Future<List<dynamic>> posts = load();
  Timer? conversationTimer;
  Timer? refreshTimer;
  int nextLine = 0;
  bool sending = false;
  bool refreshing = false;

  Future<List<dynamic>> load() => widget.loadPosts?.call() ?? sb.from('mobile_posts')
      .select('id, user_id, content, created_at, profiles:mobile_profiles(name)')
      .order('created_at', ascending: false).limit(50);

  void addLine(DateTime time) {
    final line = forumConversation[nextLine];
    nextLine = (nextLine + 1) % forumConversation.length;
    conversation.add((author: line.author, text: line.text, time: time, own: false));
    if (conversation.length > conversationWindow) conversation.removeAt(0);
  }

  Future<void> refresh() async {
    if (refreshing || sending) return;
    refreshing = true;
    try {
      final rows = await load();
      if (mounted && !sending) setState(() => posts = Future.value(rows));
    } catch (_) {
      // Keep the visible messages while a background refresh is unavailable.
    } finally {
      refreshing = false;
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    for (var i = 3; i > 0; i--) {
      addLine(now.subtract(interval * i));
    }
    conversationTimer = Timer.periodic(interval, (_) {
      setState(() => addLine(DateTime.now()));
    });
    refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) => unawaited(refresh()));
  }

  @override
  void dispose() {
    conversationTimer?.cancel();
    refreshTimer?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final content = ctrl.text.trim();
    if (sending || content.isEmpty) return;
    setState(() => sending = true);
    try {
      await sb.from('mobile_posts').insert({'user_id': sb.auth.currentUser!.id, 'content': content});
      if (!mounted) return;
      if (ctrl.text.trim() == content) ctrl.clear();
      setState(() => posts = load());
    } catch (_) {
      if (mounted) toast(context, 'Kiriman gagal dikirim. Coba lagi.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: FutureBuilder<List<dynamic>>(
          future: posts,
          builder: (context, snapshot) {
            final ownId = widget.loadPosts == null ? sb.auth.currentUser?.id : null;
            final entries = <_ForumEntry>[
              ...conversation,
              for (final row in snapshot.data ?? const [])
                (
                  author: row['profiles']?['name'] as String? ?? 'Anonim',
                  text: row['content'] as String,
                  time: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.utc(1970),
                  own: ownId != null && row['user_id'] == ownId,
                ),
            ]..sort((a, b) => b.time.compareTo(a.time));
            return Column(
              children: [
                if (snapshot.hasError)
                  LoadError(onRetry: () => setState(() => posts = load())),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.builder(
                      reverse: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _ForumMessage(entry: entry);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(child: TextField(
                controller: ctrl, minLines: 1, maxLines: 4, maxLength: 2000,
                decoration: const InputDecoration(labelText: 'Tulis di forum', counterText: ''),
              )),
              IconButton(tooltip: 'Kirim', onPressed: sending ? null : send, icon: const Icon(Icons.send)),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ForumMessage extends StatelessWidget {
  const _ForumMessage({required this.entry});

  final _ForumEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = entry.author.trim().split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty).take(2).map((part) => part.characters.first).join();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: entry.own ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!entry.own) ...[
            CircleAvatar(radius: 17, child: Text(initials.isEmpty ? '?' : initials)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: entry.own ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.own ? 'Kamu' : entry.author, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(entry.text),
                  const SizedBox(height: 4),
                  Text(DateFormat('HH:mm').format(entry.time.toLocal()), style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
