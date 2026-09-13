import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/network/api_client.dart';
import '../database/local_database.dart';
import '../models/task.dart';
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
  const TaskService();

  // Compatibilidad temporal con SyncService.
  // Después también migraremos SyncService a ApiClient.dio.
  static String get baseUrl => ApiClient.dio.options.baseUrl;

  Future<TaskLoadResult> getTasksOfflineFirst() async {
    final db = LocalDatabase.instance;

    try {
      await SyncService.instance.processPendingQueue();

      final response = await ApiClient.dio.get('/tareas');

      final data = Map<String, dynamic>.from(response.data);

      final List<dynamic> raw = data['tareas'] ?? [];

      final tasks = raw
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Conflictos: "server wins".
      // La copia del servidor sustituye el caché local.
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
      await ApiClient.dio.post(
        '/tareas',
        data: {
          'titulo': title,
          'descripcion': description,
          'client_operation_id': clientOperationId,
        },
      );

      return true;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        await LocalDatabase.instance.addPendingCreate(
          clientOperationId: clientOperationId,
          title: title,
          description: description,
        );

        return false;
      }

      throw Exception(_errorMessage(e));
    }
  }

  Future<void> updateTask({
    required int id,
    required String title,
    required String description,
    String status = 'Pendiente',
  }) async {
    try {
      await ApiClient.dio.put(
        '/tareas/$id',
        data: {'titulo': title, 'descripcion': description, 'estado': status},
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await ApiClient.dio.delete('/tareas/$id');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown;
  }

  String _errorMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      return data['mensaje']?.toString() ??
          'Error en la solicitud (${e.response?.statusCode})';
    }

    if (data is Map) {
      return data['mensaje']?.toString() ??
          'Error en la solicitud (${e.response?.statusCode})';
    }

    if (_isNetworkError(e)) {
      return 'No se pudo conectar con el servidor';
    }

    return 'Error en la solicitud (${e.response?.statusCode ?? 'desconocido'})';
  }
}
