import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNote {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  const LocalNote({required this.id, required this.title, required this.content, required this.updatedAt});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'content': content, 'updatedAt': updatedAt.toIso8601String()};
  factory LocalNote.fromJson(Map<String, dynamic> json) => LocalNote(
        id: json['id'] as String,
        title: (json['id'] as String).startsWith('example-note-')
            ? (json['title'] as String).replaceFirst(RegExp(r'^Contoh · '), '')
            : json['title'] as String,
        content: json['id'] == 'example-note-1'
            ? (json['content'] as String).replaceFirst('Sesi baca contoh berlangsung', 'Sesi baca berlangsung')
            : json['content'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class LocalNoteRepository {
  LocalNoteRepository({this.includeExamples = false});

  final bool includeExamples;
  static const _key = 'donasi_local_notes';
  static const _examplesAdded = 'donasi_note_examples_added';

  Future<List<LocalNote>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final notes = raw.map((item) => LocalNote.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
    if (includeExamples && prefs.getBool(_examplesAdded) != true) {
      final examples = [
        ('Perlengkapan sekolah', 'Cek jumlah tas, buku tulis, dan alat tulis sebelum paket dibagikan.'),
        ('Jadwal ruang baca', 'Siapkan buku untuk kelompok pemula. Sesi baca berlangsung Selasa dan Kamis sore.'),
        ('Catatan kebun warga', 'Bedeng pertama untuk bayam dan kangkung. Siapkan kompos sebelum menanam.'),
        ('Perawatan kursi roda', 'Periksa rem, putaran roda, dan kondisi dudukan sebelum dipinjamkan.'),
      ];
      for (final (index, example) in examples.indexed) {
        final id = 'example-note-$index';
        if (notes.any((note) => note.id == id)) continue;
        notes.add(LocalNote(
          id: id,
          title: example.$1,
          content: example.$2,
          updatedAt: DateTime.utc(2026, 11, 26),
        ));
      }
      await _write(notes);
      await prefs.setBool(_examplesAdded, true);
    }
    return notes;
  }

  Future<void> save(LocalNote note) async {
    final notes = await readAll();
    final index = notes.indexWhere((item) => item.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
    await _write(notes);
  }

  Future<void> delete(String id) async {
    final notes = await readAll();
    await _write(notes.where((item) => item.id != id).toList());
  }

  Future<void> _write(List<LocalNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, notes.map((item) => jsonEncode(item.toJson())).toList());
  }
}
