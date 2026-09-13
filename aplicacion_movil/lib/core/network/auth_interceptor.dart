import 'package:dio/dio.dart';

import '../../services/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Login y refresh no necesitan access token.
    final isAuthRoute =
        options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh');

    if (!isAuthRoute) {
      final token = await SecureStorageService.getAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}
