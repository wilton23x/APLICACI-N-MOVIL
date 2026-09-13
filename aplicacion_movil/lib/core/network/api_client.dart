import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
import 'auth_interceptor.dart';
import 'refresh_interceptor.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = _createDio();

  static Dio _createDio() {
    AppConfig.validate();

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 1. Agrega automáticamente el access token.
    dio.interceptors.add(AuthInterceptor());

    // 2. Si recibe 401, renueva el token
    // y reintenta la petición una sola vez.
    dio.interceptors.add(RefreshInterceptor(dio));

    // Registro mínimo únicamente en desarrollo.
    // No imprime headers, tokens ni cuerpos.
    if (!AppConfig.isProduction) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (object) {
            debugPrint('[HTTP] $object');
          },
        ),
      );
    }

    return dio;
  }
}
