import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

class CampaignList extends StatefulWidget {
  const CampaignList({super.key});
  @override
  State<CampaignList> createState() => _CampaignListState();
}

class _CampaignListState extends State<CampaignList> {
  late Future<List<dynamic>> f = _load();
  Future<List<dynamic>> _load() => sb.from('campaigns').select().order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Galang Dana'),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCampaign()));
            setState(() => f = _load());
          },
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() => f = _load()),
          child: FutureBuilder<List<dynamic>>(
            future: f,
            builder: (_, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              return ListView(children: [
                for (final c in s.data!)
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(c['title']),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: (c['collected'] / c['target']).clamp(0.0, 1.0).toDouble()),
                        Text('${rp(c['collected'])} / ${rp(c['target'])}${c['status'] == 'ended' ? '  •  Selesai' : ''}'),
                      ]),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => CampaignDetail(id: c['id'])));
                        setState(() => f = _load());
                      },
                    ),
                  ),
              ]);
            },
          ),
        ),
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

  Future<void> save() async {
    final t = int.tryParse(target.text) ?? 0;
    final allocs = [for (final r in rows) if (r[0].text.isNotEmpty) {'label': r[0].text, 'amount': int.tryParse(r[1].text) ?? 0}];
    final sum = allocs.fold<int>(0, (a, b) => a + (b['amount'] as int));
    if (t <= 0 || title.text.isEmpty) return toast(context, 'Judul dan target wajib diisi');
    if (sum != t) return toast(context, 'Total alokasi (${rp(sum)}) harus sama dengan target (${rp(t)})');
    try {
      final c = await sb.from('campaigns').insert({'owner_id': sb.auth.currentUser!.id, 'title': title.text, 'description': desc.text, 'target': t}).select().single();
      await sb.from('allocations').insert([for (final a in allocs) {...a, 'campaign_id': c['id']}]);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, '$e');
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
          FilledButton(onPressed: save, child: const Text('Terbitkan')),
        ]),
      );
}

class CampaignDetail extends StatefulWidget {
  final String id;
  const CampaignDetail({super.key, required this.id});
  @override
  State<CampaignDetail> createState() => _CampaignDetailState();
}

class _CampaignDetailState extends State<CampaignDetail> {
  late Future<List<dynamic>> f = _load();
  Future<List<dynamic>> _load() => Future.wait([
        sb.from('campaigns').select().eq('id', widget.id).single(),
        sb.from('allocations').select().eq('campaign_id', widget.id),
        sb.from('proofs').select().eq('campaign_id', widget.id).order('created_at'),
        sb.from('donations').select('amount, created_at, profiles(name)').eq('campaign_id', widget.id).order('created_at', ascending: false),
      ]);
  void reload() => setState(() => f = _load());

  Future<void> donate() async {
    final c = TextEditingController();
    final amt = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Donasi dari saldo'),
        content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal (Rp)')),
        actions: [TextButton(onPressed: () => Navigator.pop(context, int.tryParse(c.text)), child: const Text('Donasi'))],
      ),
    );
    if (amt == null || amt <= 0) return;
    try {
      await sb.rpc('donate', params: {'p_campaign': widget.id, 'p_amount': amt});
      reload();
    } catch (e) {
      if (mounted) toast(context, 'Gagal (saldo kurang?): $e');
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
      await sb.storage.from('proofs').upload(path, File(img.path));
      await sb.from('proofs').insert({
        'campaign_id': widget.id, 'user_id': sb.auth.currentUser!.id, 'note': note.text,
        'image_url': sb.storage.from('proofs').getPublicUrl(path), 'lat': pos.latitude, 'lng': pos.longitude,
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
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final c = s.data![0] as Map, allocs = s.data![1] as List, proofs = s.data![2] as List, dons = s.data![3] as List;
            final mine = c['owner_id'] == sb.auth.currentUser!.id, ended = c['status'] == 'ended';
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(c['title'], style: Theme.of(context).textTheme.titleLarge),
              Text(c['description'] ?? ''),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (c['collected'] / c['target']).clamp(0.0, 1.0).toDouble()),
              Text('Terkumpul ${rp(c['collected'])} dari ${rp(c['target'])}'),
              const SizedBox(height: 8),
              if (!ended && !mine) FilledButton.icon(icon: const Icon(Icons.favorite), label: const Text('Donasi'), onPressed: donate),
              if (!ended && mine) OutlinedButton(onPressed: () async { await sb.rpc('end_campaign', params: {'p_campaign': widget.id}); reload(); }, child: const Text('Akhiri Campaign')),
              if (ended && mine) FilledButton.icon(icon: const Icon(Icons.location_on), label: const Text('Unggah Bukti (wajib)'), onPressed: uploadProof),
              const Divider(height: 32),
              const Text('Alokasi Dana', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final a in allocs) ListTile(dense: true, title: Text(a['label']), trailing: Text(rp(a['amount']))),
              const Divider(height: 32),
              const Text('Bukti Penyaluran', style: TextStyle(fontWeight: FontWeight.bold)),
              if (ended && proofs.isEmpty) const Card(color: Color(0xFFFFE0B2), child: ListTile(leading: Icon(Icons.warning), title: Text('Penggalang belum mengunggah bukti'))),
              for (final p in proofs)
                Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Image.network(p['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover),
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
