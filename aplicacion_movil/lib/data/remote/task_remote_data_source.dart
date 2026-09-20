import 'dart:io';

import 'package:dio/dio.dart';

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
    String? photoPath,
    double? latitude,
    double? longitude,
  }) async {
    final formData = FormData.fromMap({
      'titulo': title,
      'descripcion': description,
      'client_operation_id': clientOperationId,
      'latitud': ?latitude,
      'longitud': ?longitude,
    });

    if (photoPath != null &&
        photoPath.isNotEmpty &&
        await File(photoPath).exists()) {
      formData.files.add(
        MapEntry(
          'foto',
          await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split(RegExp(r'[/\\]')).last,
          ),
        ),
      );
    }

    await ApiClient.dio.post('/tareas', data: formData);
  }

  Future<void> updateTask({
    required int id,
    required String title,
    required String description,
    required String status,
    String? photoPath,
    double? latitude,
    double? longitude,
  }) async {
    final formData = FormData.fromMap({
      'titulo': title,
      'descripcion': description,
      'estado': status,
      'latitud': ?latitude,
      'longitud': ?longitude,
    });

    if (photoPath != null &&
        photoPath.isNotEmpty &&
        await File(photoPath).exists()) {
      formData.files.add(
        MapEntry(
          'foto',
          await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split(RegExp(r'[/\\]')).last,
          ),
        ),
      );
    }

    await ApiClient.dio.put('/tareas/$id', data: formData);
  }

  Future<void> deleteTask(int id) async {
    await ApiClient.dio.delete('/tareas/$id');
  }
}
