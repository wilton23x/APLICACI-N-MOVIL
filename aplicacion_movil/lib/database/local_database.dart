import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'taskmanager_semana12.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY,
            titulo TEXT NOT NULL,
            descripcion TEXT,
            estado TEXT NOT NULL,
            usuario_id INTEGER,
            server_updated_at TEXT,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_operations (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_operation_id TEXT NOT NULL UNIQUE,
            operation TEXT NOT NULL,
            payload TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            last_error TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> replaceTasksFromServer(List<Task> tasks) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('tasks');
      for (final task in tasks) {
        if (task.id == null) continue;
        await txn.insert('tasks', {
          'id': task.id,
          'titulo': task.title,
          'descripcion': task.description,
          'estado': task.status,
          'usuario_id': task.userId,
          'server_updated_at': task.serverUpdatedAt?.toUtc().toIso8601String(),
          'cached_at': now,
        });
      }
      await txn.insert(
        'metadata',
        {'key': 'last_sync_at', 'value': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<Task>> getCachedTasks() async {
    final db = await database;
    final rows = await db.query('tasks', orderBy: 'id DESC');
    return rows.map(Task.fromLocalMap).toList();
  }

  Future<DateTime?> getLastSyncAt() async {
    final db = await database;
    final rows = await db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: ['last_sync_at'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value']?.toString() ?? '');
  }

  Future<void> addPendingCreate({
    required String clientOperationId,
    required String title,
    required String description,
  }) async {
    final db = await database;
    await db.insert('pending_operations', {
      'client_operation_id': clientOperationId,
      'operation': 'create_task',
      'payload': jsonEncode({
        'titulo': title,
        'descripcion': description,
        'client_operation_id': clientOperationId,
      }),
      'attempts': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return db.query('pending_operations', orderBy: 'local_id ASC');
  }

  Future<void> markAttempt(int localId, int attempts, String? error) async {
    final db = await database;
    await db.update(
      'pending_operations',
      {'attempts': attempts, 'last_error': error},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> removePending(int localId) async {
    final db = await database;
    await db.delete('pending_operations', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<int> pendingCount() async {
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pending_operations'),
    );
    return result ?? 0;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('pending_operations');
      await txn.delete('tasks');
      await txn.delete('metadata');
    });
  }
}
