import 'package:dio/dio.dart';

import '../../services/secure_storage_service.dart';

class RefreshInterceptor extends Interceptor {
  final Dio dio;

  RefreshInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;

    final is401 = err.response?.statusCode == 401;

    final alreadyRetried = request.extra['retried'] == true;

    final isAuthRoute =
        request.path.contains('/auth/login') ||
        request.path.contains('/auth/refresh');

    if (!is401 || alreadyRetried || isAuthRoute) {
      return handler.next(err);
    }

    request.extra['retried'] = true;

    try {
      final refreshToken = await SecureStorageService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        await SecureStorageService.deleteTokens();

        return handler.next(err);
      }

      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'retried': true}),
      );

      final data = Map<String, dynamic>.from(response.data);

      final newAccessToken = data['access_token']?.toString();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await SecureStorageService.deleteTokens();

        return handler.next(err);
      }

      await SecureStorageService.saveAccessToken(newAccessToken);

      request.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await dio.fetch<dynamic>(request);

      return handler.resolve(retryResponse);
    } on DioException {
      await SecureStorageService.deleteTokens();

      return handler.next(err);
    } catch (_) {
      await SecureStorageService.deleteTokens();

      return handler.next(err);
    }
  }
}
