import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/network_exception_mapper.dart';
import '../../models/task.dart';
import '../../services/sync_service.dart';
import '../local/task_local_data_source.dart';
import '../remote/task_remote_data_source.dart';

class TaskRepositoryResult {
  final List<Task> tasks;
  final bool fromCache;
  final DateTime? lastSyncAt;

  const TaskRepositoryResult({
    required this.tasks,
    required this.fromCache,
    this.lastSyncAt,
  });
}

class TaskRepository {
  final TaskRemoteDataSource remote;
  final TaskLocalDataSource local;

  TaskRepository({TaskRemoteDataSource? remote, TaskLocalDataSource? local})
    : remote = remote ?? TaskRemoteDataSource(),
      local = local ?? TaskLocalDataSource();

  Future<TaskRepositoryResult> getTasks() async {
    try {
      await syncPending();

      final tasks = await remote.getTasks();

      await local.replaceTasksFromServer(tasks);

      return TaskRepositoryResult(
        tasks: tasks,
        fromCache: false,
        lastSyncAt: await local.getLastSyncAt(),
      );
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        final cached = await local.getCachedTasks();

        return TaskRepositoryResult(
          tasks: cached,
          fromCache: true,
          lastSyncAt: await local.getLastSyncAt(),
        );
      }

      throw Exception(NetworkExceptionMapper.message(e));
    } catch (_) {
      final cached = await local.getCachedTasks();

      return TaskRepositoryResult(
        tasks: cached,
        fromCache: true,
        lastSyncAt: await local.getLastSyncAt(),
      );
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    String? photoPath,
    double? latitude,
    double? longitude,
  }) async {
    final clientOperationId = const Uuid().v4();

    try {
      await remote.createTask(
        title: title,
        description: description,
        clientOperationId: clientOperationId,
        photoPath: photoPath,
        latitude: latitude,
        longitude: longitude,
      );

      return true;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        await local.addPendingCreate(
          clientOperationId: clientOperationId,
          title: title,
          description: description,
          photoPath: photoPath,
          latitude: latitude,
          longitude: longitude,
        );

        return false;
      }

      throw Exception(NetworkExceptionMapper.message(e));
    }
  }

  Future<void> updateTask({
    required int id,
    required String title,
    required String description,
    String status = 'Pendiente',
    String? photoPath,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await remote.updateTask(
        id: id,
        title: title,
        description: description,
        status: status,
        photoPath: photoPath,
        latitude: latitude,
        longitude: longitude,
      );
    } on DioException catch (e) {
      throw Exception(NetworkExceptionMapper.message(e));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await remote.deleteTask(id);
    } on DioException catch (e) {
      throw Exception(NetworkExceptionMapper.message(e));
    }
  }

  Future<int> pendingCount() async {
    return local.pendingCount();
  }

  Future<void> syncPending() async {
    await SyncService.instance.processPendingQueue();
  }

  Future<void> clearLocalData() async {
    await local.clearAll();
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }
}




