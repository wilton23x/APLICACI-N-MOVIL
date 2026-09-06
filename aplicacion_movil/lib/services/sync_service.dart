import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../database/local_database.dart';
import 'secure_storage_service.dart';
import 'task_service.dart';

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
    if (!await hasNetwork()) return;

    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) return;

    final pending = await _localDb.getPendingOperations();
    for (final op in pending) {
      final localId = op['local_id'] as int;
      final attempts = (op['attempts'] as int?) ?? 0;
      if (attempts >= maxAttempts) continue;

      try {
        final payload = jsonDecode(op['payload'] as String) as Map<String, dynamic>;
        final response = await http
            .post(
              Uri.parse('${TaskService.baseUrl}/tareas'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 201 || response.statusCode == 200) {
          await _localDb.removePending(localId);
        } else {
          await _localDb.markAttempt(
            localId,
            attempts + 1,
            'HTTP ${response.statusCode}',
          );
        }
      } on SocketException catch (e) {
        await _localDb.markAttempt(localId, attempts + 1, e.message);
        break;
      } catch (e) {
        await _localDb.markAttempt(localId, attempts + 1, e.toString());
      }

      final nextAttempt = attempts + 1;
      if (nextAttempt < maxAttempts) {
        final seconds = 1 << nextAttempt; // 2, 4, 8, 16 s
        await Future.delayed(Duration(seconds: seconds));
      }
    }
  }
}
