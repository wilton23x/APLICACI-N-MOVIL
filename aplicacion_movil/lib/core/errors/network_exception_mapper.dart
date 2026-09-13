import 'package:dio/dio.dart';

class NetworkExceptionMapper {
  static String message(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (_isNetworkError(error)) {
      return 'Sin conexión a Internet o tiempo de espera agotado.';
    }

    if (statusCode == 401) {
      return 'La sesión expiró. Inicia sesión nuevamente.';
    }

    if (statusCode == 422) {
      if (data is Map) {
        final errores = data['errores'];

        if (errores is Map) {
          for (final value in errores.values) {
            if (value is List && value.isNotEmpty) {
              return value.first.toString();
            }

            if (value != null) {
              return value.toString();
            }
          }
        }

        final mensaje = data['mensaje'];

        if (mensaje != null) {
          return mensaje.toString();
        }
      }

      return 'Los datos enviados no son válidos.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'El servidor no está disponible en este momento.';
    }

    if (data is Map && data['mensaje'] != null) {
      return data['mensaje'].toString();
    }

    return 'Ocurrió un error al procesar la solicitud.';
  }

  static bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.unknown;
  }
}
