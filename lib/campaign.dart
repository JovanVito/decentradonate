import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'donation_amount.dart';

class CampaignList extends StatefulWidget {
  const CampaignList({super.key, this.fundraising = false, this.onDonation});

  final bool fundraising;
  final VoidCallback? onDonation;
  @override
  State<CampaignList> createState() => _CampaignListState();
}

class _CampaignListState extends State<CampaignList> {
  bool mineOnly = false;
  late Future<List<dynamic>> f = _load();
  Future<List<dynamic>> _load() => sb.from('mobile_campaigns').select().order('created_at', ascending: false);

  Future<void> openCampaign(String id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CampaignDetail(id: id, onDonation: widget.onDonation),
    ));
    if (mounted) setState(() => f = _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: !widget.fundraising ? null : FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Galang Dana'),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCampaign()));
            if (mounted) setState(() => f = _load());
          },
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() => f = _load()),
          child: FutureBuilder<List<dynamic>>(
            future: f,
            builder: (_, s) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                if (s.hasError) LoadError(onRetry: () => setState(() => f = _load())),
                if (s.connectionState == ConnectionState.waiting && !s.hasData)
                  const LinearProgressIndicator(),
                if (widget.fundraising)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilterChip(
                        label: const Text('Campaign saya'),
                        selected: mineOnly,
                        onSelected: (selected) => setState(() => mineOnly = selected),
                      ),
                    ),
                  ),
                if (widget.fundraising && mineOnly && s.hasData &&
                    !s.data!.any((campaign) => campaign['owner_id'] == sb.auth.currentUser!.id))
                  const ListTile(title: Text('Belum ada campaign yang kamu buat.')),
                for (final c in s.data ?? const [])
                  if (!widget.fundraising || !mineOnly || c['owner_id'] == sb.auth.currentUser!.id)
                  Card(
                    margin: const EdgeInsets.all(8),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => openCampaign(c['id'] as String),
                      child: Column(
                      children: [
                        if (c['cover_photo'] case final int photo)
                          _CampaignCover(photo: photo, height: 150),
                        ListTile(
                      title: Text(c['title']),
                      trailing: c['status'] == 'active' && c['owner_id'] != sb.auth.currentUser!.id
                          ? TextButton(onPressed: () => openCampaign(c['id'] as String), child: const Text('Donasi'))
                          : const Icon(Icons.chevron_right),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (c['goal'] case final String goal) Text(goal),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: (c['collected'] / c['target']).clamp(0.0, 1.0).toDouble()),
                        Text('${rp(c['collected'])} / ${rp(c['target'])}${c['status'] == 'ended' ? '  •  Selesai' : ''}'),
                      ]),
                        ),
                      ],
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ),
      );
}

class _CampaignCover extends StatelessWidget {
  const _CampaignCover({required this.photo, required this.height});

  final int photo;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/campaigns/$photo.jpg',
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
  );
}

class CreateCampaign extends StatefulWidget {
  const CreateCampaign({super.key});
  @override
  State<CreateCampaign> createState() => _CreateCampaignState();
}

class _CreateCampaignState extends State<CreateCampaign> {
  final title = TextEditingController(), desc = TextEditingController(), target = TextEditingController();
  final rows = <List<TextEditingController>>[[TextEditingController(), TextEditingController()]];
  bool saving = false;

  Future<void> save() async {
    if (saving) return;
    final t = int.tryParse(target.text) ?? 0;
    final allocs = [for (final r in rows) if (r[0].text.isNotEmpty) {'label': r[0].text, 'amount': int.tryParse(r[1].text) ?? 0}];
    final sum = allocs.fold<int>(0, (a, b) => a + (b['amount'] as int));
    if (t <= 0 || title.text.isEmpty) return toast(context, 'Judul dan target wajib diisi');
    if (sum != t) return toast(context, 'Total alokasi (${rp(sum)}) harus sama dengan target (${rp(t)})');
    setState(() => saving = true);
    try {
      await sb.rpc('mobile_create_campaign', params: {
        'p_title': title.text.trim(),
        'p_description': desc.text.trim(),
        'p_target': t,
        'p_allocations': allocs,
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) toast(context, 'Campaign gagal diterbitkan. Periksa isian dan coba lagi.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Buat Campaign')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul')),
          TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi')),
          TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target dana (Rp)')),
          const SizedBox(height: 16),
          const Text('Rencana Alokasi Dana (terlihat publik)', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final r in rows)
            Row(children: [
              Expanded(flex: 3, child: TextField(controller: r[0], decoration: const InputDecoration(labelText: 'Peruntukan'))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: r[1], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rp'))),
            ]),
          TextButton.icon(icon: const Icon(Icons.add), label: const Text('Tambah pos'), onPressed: () => setState(() => rows.add([TextEditingController(), TextEditingController()]))),
          FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Menerbitkan…' : 'Terbitkan')),
        ]),
      );
}

class CampaignDetail extends StatefulWidget {
  final String id;
  final VoidCallback? onDonation;
  const CampaignDetail({super.key, required this.id, this.onDonation});
  @override
  State<CampaignDetail> createState() => _CampaignDetailState();
}

class _CampaignDetailState extends State<CampaignDetail> {
  bool donating = false;
  late Future<List<dynamic>> f = _load();
  Future<List<dynamic>> _load() => Future.wait([
        sb.from('mobile_campaigns').select().eq('id', widget.id).single(),
        sb.from('mobile_allocations').select().eq('campaign_id', widget.id),
        _loadProofs(),
        sb.from('mobile_donations').select('amount, created_at, profiles:mobile_profiles(name)').eq('campaign_id', widget.id).order('created_at', ascending: false),
      ]);
  Future<List<Map<String, dynamic>>> _loadProofs() async {
    final rows = await sb.from('mobile_proofs').select()
        .eq('campaign_id', widget.id).order('created_at');
    return Future.wait(rows.map((row) async => {
      ...row,
      'signed_url': await sb.storage.from('mobile-proofs')
          .createSignedUrl(row['image_url'] as String, 3600),
    }));
  }

  void reload() {
    if (mounted) setState(() => f = _load());
  }

  Future<void> donate() async {
    if (donating) return;
    setState(() => donating = true);
    try {
      final amt = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const DonationAmountSheet(),
      );
      if (!mounted || amt == null) return;
      await sb.rpc('mobile_donate', params: {'p_campaign': widget.id, 'p_amount': amt});
      widget.onDonation?.call();
      if (!mounted) return;
      reload();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(children: [
            const Icon(Icons.favorite, color: Colors.pinkAccent),
            const SizedBox(width: 6),
            const Text('+1', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(child: Text('Donasi ${rp(amt)} berhasil.')),
          ]),
        ));
    } on PostgrestException catch (error) {
      if (mounted) {
        toast(context, switch (error.message) {
          'Saldo tidak cukup' => 'Saldo tidak cukup. Tambah saldo di Dompet.',
          'Campaign tidak dapat menerima donasi' => 'Campaign ini tidak dapat menerima donasi.',
          _ => 'Donasi gagal diproses. Periksa riwayat sebelum mencoba lagi.',
        });
      }
    } catch (_) {
      if (mounted) toast(context, 'Status donasi belum diketahui. Periksa riwayat sebelum mencoba lagi.');
    } finally {
      if (mounted) setState(() => donating = false);
    }
  }

  Future<void> uploadProof() async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bukti Penyaluran'),
        content: TextField(controller: note, decoration: const InputDecoration(labelText: 'Keterangan')),
        actions: [TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ambil Foto + GPS'))],
      ),
    );
    if (ok != true) return;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw 'Izin lokasi wajib untuk bukti';
      // Wajib kamera (bukan galeri) agar foto diambil di lokasi saat itu
      final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
      if (img == null) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (pos.isMocked) throw 'Lokasi palsu (mock GPS) terdeteksi';
      final path = '${widget.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await sb.storage.from('mobile-proofs').upload(path, File(img.path));
      await sb.from('mobile_proofs').insert({
        'campaign_id': widget.id, 'user_id': sb.auth.currentUser!.id, 'note': note.text,
        'image_url': path, 'lat': pos.latitude, 'lng': pos.longitude,
      });
      reload();
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detail Campaign')),
        body: FutureBuilder<List<dynamic>>(
          future: f,
          builder: (_, s) {
            if (s.hasError) return LoadError(onRetry: () => setState(() => f = _load()));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final c = s.data![0] as Map, allocs = s.data![1] as List, proofs = s.data![2] as List, dons = s.data![3] as List;
            final mine = c['owner_id'] == sb.auth.currentUser!.id, ended = c['status'] == 'ended';
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (c['cover_photo'] case final int photo)
                _CampaignCover(photo: photo, height: 210),
              Text(c['title'], style: Theme.of(context).textTheme.titleLarge),
              if (c['goal'] case final String goal) Text(goal, style: Theme.of(context).textTheme.titleMedium),
              Text(c['description'] ?? ''),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (c['collected'] / c['target']).clamp(0.0, 1.0).toDouble()),
              Text('Terkumpul ${rp(c['collected'])} dari ${rp(c['target'])}'),
              const SizedBox(height: 8),
              if (!ended && !mine) FilledButton.icon(
                icon: const Icon(Icons.favorite),
                label: Text(donating ? 'Memproses…' : 'Donasi'),
                onPressed: donating ? null : donate,
              ),
              if (!ended && mine) OutlinedButton(onPressed: () async { await sb.rpc('mobile_end_campaign', params: {'p_campaign': widget.id}); reload(); }, child: const Text('Akhiri Campaign')),
              if (ended && mine) FilledButton.icon(icon: const Icon(Icons.location_on), label: const Text('Unggah Bukti (wajib)'), onPressed: uploadProof),
              const Divider(height: 32),
              const Text('Alokasi Dana', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final a in allocs) ListTile(dense: true, title: Text(a['label']), trailing: Text(rp(a['amount']))),
              const Divider(height: 32),
              const Text('Bukti Penyaluran', style: TextStyle(fontWeight: FontWeight.bold)),
              if (ended && proofs.isEmpty) const Card(color: Color(0xFFFFE0B2), child: ListTile(leading: Icon(Icons.warning), title: Text('Penggalang belum mengunggah bukti'))),
              for (final p in proofs)
                Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Image.network(p['signed_url'], errorBuilder: (context, error, stackTrace) => const Text('Foto bukti gagal dimuat'), height: 200, width: double.infinity, fit: BoxFit.cover),
                  ListTile(title: Text(p['note'] ?? ''), subtitle: Text('GPS: ${p['lat'].toStringAsFixed(5)}, ${p['lng'].toStringAsFixed(5)}\n${'${p['created_at']}'.substring(0, 16)}')),
                ])),
              const Divider(height: 32),
              const Text('Daftar Donatur', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final d in dons) ListTile(dense: true, title: Text(d['profiles']?['name'] ?? 'Anonim'), trailing: Text(rp(d['amount']))),
            ]);
          },
        ),
      );
}
