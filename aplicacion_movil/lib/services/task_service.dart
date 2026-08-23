import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:3000/api';

  final String token;

  const TaskService({required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Task>> getTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tareas'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }

    final data = jsonDecode(response.body);
    final List<dynamic> tareas = data['tareas'] ?? [];

    return tareas
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask({
    required String title,
    required String description,
    String status = 'Pendiente',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tareas'),
      headers: _headers,
      body: jsonEncode({'titulo': title, 'descripcion': description}),
    );

    if (response.statusCode != 201) {
      throw Exception(_errorMessage(response));
    }

    final data = jsonDecode(response.body);

    return Task(
      id: data['id'],
      title: title,
      description: description,
      status: status,
    );
  }

  Future<void> updateTask({
    required int id,
    required String title,
    required String description,
    String status = 'Pendiente',
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tareas/$id'),
      headers: _headers,
      body: jsonEncode({
        'titulo': title,
        'descripcion': description,
        'estado': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tareas/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      return data['mensaje']?.toString() ??
          'Error en la solicitud (${response.statusCode})';
    } catch (_) {
      return 'Error en la solicitud (${response.statusCode})';
    }
  }
}
