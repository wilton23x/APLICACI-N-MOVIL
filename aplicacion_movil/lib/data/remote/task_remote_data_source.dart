import '../../core/network/api_client.dart';
import '../../models/task.dart';

class TaskRemoteDataSource {
  Future<List<Task>> getTasks() async {
    final response = await ApiClient.dio.get('/tareas');

    final data = Map<String, dynamic>.from(response.data);

    final List<dynamic> raw = data['tareas'] ?? [];

    return raw
        .map((item) => Task.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> createTask({
    required String title,
    required String description,
    required String clientOperationId,
  }) async {
    await ApiClient.dio.post(
      '/tareas',
      data: {
        'titulo': title,
        'descripcion': description,
        'client_operation_id': clientOperationId,
      },
    );
  }

  Future<void> updateTask({
    required int id,
    required String title,
    required String description,
    required String status,
  }) async {
    await ApiClient.dio.put(
      '/tareas/$id',
      data: {'titulo': title, 'descripcion': description, 'estado': status},
    );
  }

  Future<void> deleteTask(int id) async {
    await ApiClient.dio.delete('/tareas/$id');
  }
}
