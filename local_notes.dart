import 'package:flutter/material.dart';
import 'local_repository.dart';

class LocalNotesController extends ChangeNotifier {
  final LocalNoteRepository repository;
  LocalNotesController(this.repository);

  List<LocalNote> notes = [];
  bool loading = true;
  bool saving = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      notes = await repository.readAll();
    } catch (_) {
      error = 'Data lokal gagal dibaca';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save({String? id, required String title, required String content}) async {
    if (title.trim().isEmpty || content.trim().isEmpty) throw FormatException('Judul dan isi wajib diisi');
    saving = true;
    notifyListeners();
    try {
      await repository.save(LocalNote(
        id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
        content: content.trim(),
        updatedAt: DateTime.now(),
      ));
      notes = await repository.readAll();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await repository.delete(id);
    notes = await repository.readAll();
    notifyListeners();
  }
}

class LocalNotesPage extends StatefulWidget {
  const LocalNotesPage({super.key});
  @override
  State<LocalNotesPage> createState() => _LocalNotesPageState();
}

class _LocalNotesPageState extends State<LocalNotesPage> {
  late final LocalNotesController controller = LocalNotesController(LocalNoteRepository())..load();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> edit([LocalNote? note]) async {
    final title = TextEditingController(text: note?.title);
    final content = TextEditingController(text: note?.content);
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(note == null ? 'Catatan Donasi' : 'Edit Catatan'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Judul'), validator: (v) => v!.trim().isEmpty ? 'Judul wajib diisi' : null),
            TextFormField(controller: content, decoration: const InputDecoration(labelText: 'Isi'), minLines: 2, maxLines: 4, validator: (v) => v!.trim().isEmpty ? 'Isi wajib diisi' : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ListenableBuilder(
            listenable: controller,
            builder: (_, __) => FilledButton(
              onPressed: controller.saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                await controller.save(id: note?.id, title: title.text, content: content.text);
                if (mounted) Navigator.pop(context);
              },
              child: controller.saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Catatan Lokal')),
          floatingActionButton: FloatingActionButton.extended(onPressed: () => edit(), icon: const Icon(Icons.add), label: const Text('Tambah')),
          body: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : controller.error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(controller.error!), ElevatedButton(onPressed: controller.load, child: const Text('Coba lagi'))]))
                  : controller.notes.isEmpty
                      ? const Center(child: Text('Belum ada catatan'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: controller.notes.length,
                          itemBuilder: (_, index) {
                            final note = controller.notes[index];
                            return Card(child: ListTile(title: Text(note.title), subtitle: Text(note.content), onTap: () => edit(note), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => controller.remove(note.id))));
                          },
                        ),
        ),
      );
}
