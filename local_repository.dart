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
        title: json['title'] as String,
        content: json['content'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class LocalNoteRepository {
  static const _key = 'donasi_local_notes';

  Future<List<LocalNote>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((item) => LocalNote.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
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
