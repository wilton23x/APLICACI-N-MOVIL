import '../../database/local_database.dart';
import '../../models/task.dart';

class TaskLocalDataSource {
  final LocalDatabase _db;

  TaskLocalDataSource({LocalDatabase? database})
    : _db = database ?? LocalDatabase.instance;

  Future<List<Task>> getCachedTasks() async {
    return _db.getCachedTasks();
  }

  Future<void> replaceTasksFromServer(List<Task> tasks) async {
    await _db.replaceTasksFromServer(tasks);
  }

  Future<DateTime?> getLastSyncAt() async {
    return _db.getLastSyncAt();
  }

  Future<void> addPendingCreate({
    required String clientOperationId,
    required String title,
    required String description,
    String? photoPath,
    double? latitude,
    double? longitude,
  }) async {
    await _db.addPendingCreate(
      clientOperationId: clientOperationId,
      title: title,
      description: description,
      photoPath: photoPath,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<int> pendingCount() async {
    return _db.pendingCount();
  }

  Future<void> clearAll() async {
    await _db.clearAll();
  }
}
