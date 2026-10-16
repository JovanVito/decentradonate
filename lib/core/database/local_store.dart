import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// Conditional import: di web memakai platform_web.dart, selain itu platform_io.dart.
import 'platform_io.dart' if (dart.library.js_interop) 'platform_web.dart'
    as platform;

/// Penyimpanan lokal kontak wallet dengan dua backend:
/// - Android/iOS/desktop: SQLite (`sqflite`).
/// - Web (Chrome): `shared_preferences` (tersimpan di localStorage).
///
/// `sqflite` tidak jalan di web, jadi backend dipilih saat runtime. Kontrak
/// CRUD-nya sama sehingga UI dan provider tidak perlu tahu bedanya.
class LocalStore {
  LocalStore({bool? isWeb}) : isWeb = isWeb ?? platform.isWebPlatform();

  final bool isWeb;

  static const _table = 'wallet_contacts';
  static const _webKey = 'wallet_contacts';

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'decentradonate.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            added_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// READ — semua baris, terbaru lebih dulu.
  Future<List<Map<String, Object?>>> readAll() async {
    if (isWeb) return _readWeb();
    final db = await _database();
    return db.query(_table, orderBy: 'added_at DESC');
  }

  /// CREATE — insert baris baru, kembalikan id.
  Future<int> insert(Map<String, Object?> row) async {
    if (isWeb) return _insertWeb(row);
    final db = await _database();
    final copy = Map<String, Object?>.from(row)..remove('id');
    return db.insert(_table, copy);
  }

  /// UPDATE — ubah baris berdasarkan id.
  Future<void> update(int id, Map<String, Object?> row) async {
    if (isWeb) return _updateWeb(id, row);
    final db = await _database();
    await db.update(_table, row, where: 'id = ?', whereArgs: [id]);
  }

  /// DELETE — hapus baris berdasarkan id.
  Future<void> delete(int id) async {
    if (isWeb) return _deleteWeb(id);
    final db = await _database();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- WEB: shared_preferences (localStorage) ----------------

  Future<List<Map<String, Object?>>> _readWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => Map<String, Object?>.from(e as Map))
        .toList();
    list.sort((a, b) => (b['added_at'] as int).compareTo(a['added_at'] as int));
    return list;
  }

  Future<int> _insertWeb(Map<String, Object?> row) async {
    final rows = await _readWeb();
    final nextId = rows.isEmpty
        ? 1
        : (rows.map((r) => r['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    rows.add({...row, 'id': nextId});
    await _saveWeb(rows);
    return nextId;
  }

  Future<void> _updateWeb(int id, Map<String, Object?> row) async {
    final rows = await _readWeb();
    final index = rows.indexWhere((r) => r['id'] == id);
    if (index == -1) return;
    rows[index] = {...row, 'id': id};
    await _saveWeb(rows);
  }

  Future<void> _deleteWeb(int id) async {
    final rows = await _readWeb();
    rows.removeWhere((r) => r['id'] == id);
    await _saveWeb(rows);
  }

  Future<void> _saveWeb(List<Map<String, Object?>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webKey, jsonEncode(rows));
  }
}
