import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<String> login({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['mensaje']?.toString() ?? 'No se pudo iniciar sesión',
      );
    }

    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('La API no devolvió un token');
    }

    return token;
  }
}
