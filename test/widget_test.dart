import 'package:flutter_test/flutter_test.dart';
import 'package:donasi_transparan/local_repository.dart';

void main() {
  test('LocalNote model serializes and restores', () {
    final note = LocalNote(id: '1', title: 'Donasi', content: 'Bantuan', updatedAt: DateTime.utc(2026, 1, 1));
    final restored = LocalNote.fromJson(note.toJson());
    expect(restored.id, '1');
    expect(restored.title, 'Donasi');
    expect(restored.content, 'Bantuan');
    expect(restored.updatedAt, note.updatedAt);
  });
}
