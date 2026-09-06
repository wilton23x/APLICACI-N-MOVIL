import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../database/local_database.dart';
import '../models/task.dart';
import 'secure_storage_service.dart';
import 'sync_service.dart';

class TaskLoadResult {
  final List<Task> tasks;
  final bool fromCache;
  final DateTime? lastSyncAt;

  const TaskLoadResult({
    required this.tasks,
    required this.fromCache,
    this.lastSyncAt,
  });
}

class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  const TaskService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No existe una sesión activa');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<TaskLoadResult> getTasksOfflineFirst() async {
    final db = LocalDatabase.instance;
    try {
      await SyncService.instance.processPendingQueue();
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/tareas'), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) throw Exception(_errorMessage(response));
      final data = jsonDecode(response.body);
      final List<dynamic> raw = data['tareas'] ?? [];
      final tasks = raw.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();

      // Conflictos: "server wins". La copia del servidor sustituye el cache local.
      await db.replaceTasksFromServer(tasks);
      return TaskLoadResult(
        tasks: tasks,
        fromCache: false,
        lastSyncAt: await db.getLastSyncAt(),
      );
    } catch (_) {
      final cached = await db.getCachedTasks();
      return TaskLoadResult(
        tasks: cached,
        fromCache: true,
        lastSyncAt: await db.getLastSyncAt(),
      );
    }
  }

  Future<bool> createTaskOfflineFirst({
    required String title,
    required String description,
  }) async {
    final clientOperationId = const Uuid().v4();
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/tareas'),
            headers: headers,
            body: jsonEncode({
              'titulo': title,
              'descripcion': description,
              'client_operation_id': clientOperationId,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(_errorMessage(response));
      }
      return true;
    } catch (_) {
      await LocalDatabase.instance.addPendingCreate(
        clientOperationId: clientOperationId,
        title: title,
        description: description,
      );
      return false;
    }
  }

  Future<void> updateTask({
    required int id,
    required String title,
    required String description,
    String status = 'Pendiente',
  }) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/tareas/$id'),
      headers: headers,
      body: jsonEncode({'titulo': title, 'descripcion': description, 'estado': status}),
    );
    if (response.statusCode != 200) throw Exception(_errorMessage(response));
  }

  Future<void> deleteTask(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/tareas/$id'), headers: headers);
    if (response.statusCode != 200) throw Exception(_errorMessage(response));
  }

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['mensaje']?.toString() ?? 'Error en la solicitud (${response.statusCode})';
    } catch (_) {
      return 'Error en la solicitud (${response.statusCode})';
    }
  }
}
