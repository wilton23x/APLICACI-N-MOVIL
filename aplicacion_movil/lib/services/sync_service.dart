import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../database/local_database.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  static const int maxAttempts = 5;

  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<bool> hasNetwork() async {
    final result = await Connectivity().checkConnectivity();

    return !result.contains(ConnectivityResult.none);
  }

  Future<void> processPendingQueue() async {
    if (!await hasNetwork()) {
      return;
    }

    final pending = await _localDb.getPendingOperations();

    for (final op in pending) {
      final localId = op['local_id'] as int;
      final attempts = (op['attempts'] as int?) ?? 0;

      if (attempts >= maxAttempts) {
        continue;
      }

      try {
        final payload =
            jsonDecode(op['payload'] as String) as Map<String, dynamic>;

        final photoPath = payload['foto_path']?.toString();

        final formData = FormData.fromMap({
          'titulo': payload['titulo'],
          'descripcion': payload['descripcion'],
          'client_operation_id': payload['client_operation_id'],
          'latitud': ?payload['latitud'],
          'longitud': ?payload['longitud'],
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

        await _localDb.removePending(localId);
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          await _localDb.markAttempt(
            localId,
            attempts + 1,
            'Error de conexión: ${e.message ?? 'Sin conexión'}',
          );

          break;
        }

        final statusCode = e.response?.statusCode;

        await _localDb.markAttempt(
          localId,
          attempts + 1,
          'HTTP ${statusCode ?? 'desconocido'}',
        );

        // No insistimos con errores de validación.
        if (statusCode == 400 || statusCode == 422) {
          continue;
        }

        await _waitBeforeRetry(attempts + 1);
      } catch (e) {
        await _localDb.markAttempt(localId, attempts + 1, e.toString());

        await _waitBeforeRetry(attempts + 1);
      }
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown;
  }

  Future<void> _waitBeforeRetry(int attempt) async {
    if (attempt >= maxAttempts) {
      return;
    }

    final seconds = 1 << attempt;

    await Future.delayed(Duration(seconds: seconds));
  }
}
