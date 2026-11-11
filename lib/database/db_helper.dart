import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/checkin.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._();
  DbHelper._();

  /// Screens listen to this. It goes up by one every time data changes,
  /// so each screen knows when to reload.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'checkins.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE checkins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            yesterday TEXT NOT NULL,
            goals TEXT NOT NULL,
            score REAL NOT NULL,
            label TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insert(Checkin checkin) async {
    final db = await database;
    final map = checkin.toMap();
    map.remove('id');
    final id = await db.insert('checkins', map);
    changes.value++;
    return id;
  }

  /// Newest first.
  Future<List<Checkin>> getAll() async {
    final db = await database;
    final rows = await db.query('checkins', orderBy: 'id DESC');
    return rows.map((r) => Checkin.fromMap(r)).toList();
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('checkins', where: 'id = ?', whereArgs: [id]);
    changes.value++;
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('checkins');
    changes.value++;
  }
}
