import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/auth_tokens.dart';
import 'secure_storage_service.dart';

class AuthService {
  // INICIAR SESIÓN
  Future<void> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'correo': correo,
          'password': password,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      final tokens = AuthTokens.fromJson(data);

      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        throw Exception('El servidor no devolvió los tokens correctamente');
      }

      await SecureStorageService.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map) {
        throw Exception(
          data['mensaje']?.toString() ?? 'Error al iniciar sesión',
        );
      }

      throw Exception('No se pudo conectar con el servidor');
    }
  }

  // REGISTRAR NUEVO USUARIO
  Future<String> register({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/register',
        data: {
          'nombre': nombre,
          'correo': correo,
          'password': password,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      return data['mensaje']?.toString() ??
          'Usuario registrado correctamente';
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map) {
        throw Exception(
          data['mensaje']?.toString() ?? 'Error al registrar usuario',
        );
      }

      throw Exception('No se pudo conectar con el servidor');
    }
  }
}