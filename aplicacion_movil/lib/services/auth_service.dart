import 'dart:convert';
import 'package:http/http.dart' as http;

import 'secure_storage_service.dart';

class AuthService {
  static const String baseUrl =
      'http://localhost:3000/api';

  Future<String> login({
    required String correo,
    required String password,
  }) async {

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'];

      // Guardar JWT en almacenamiento seguro
      await SecureStorageService.saveToken(token);

      return token;
    } else {
      throw Exception(
        data['mensaje'] ?? 'Error al iniciar sesión',
      );
    }
  }
}