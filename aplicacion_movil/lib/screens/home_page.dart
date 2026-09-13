import 'package:flutter/material.dart';

import '../data/repositories/task_repository.dart';
import '../models/task.dart';
import '../services/secure_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';
import '../widgets/task_card.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TaskRepository _taskRepository = TaskRepository();

  List<Task> _tasks = [];

  bool _loading = true;
  bool _fromCache = false;

  DateTime? _lastSyncAt;

  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final result = await _taskRepository.getTasks();

      final pending = await _taskRepository.pendingCount();

      if (!mounted) return;

      setState(() {
        _tasks = result.tasks;
        _fromCache = result.fromCache;
        _lastSyncAt = result.lastSyncAt;
        _pendingCount = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar tareas: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  String _ageText() {
    if (_lastSyncAt == null) {
      return 'sin sincronización previa';
    }

    final diff = DateTime.now().toUtc().difference(_lastSyncAt!.toUtc());

    if (diff.inMinutes < 1) {
      return 'hace menos de 1 minuto';
    }

    if (diff.inMinutes < 60) {
      return 'hace ${diff.inMinutes} min';
    }

    if (diff.inHours < 24) {
      return 'hace ${diff.inHours} h';
    }

    return 'hace ${diff.inDays} días';
  }

  Future<void> _saveTask({Task? task}) async {
    final bool isEditing = task != null;

    String title = task?.title ?? '';
    String description = task?.description ?? '';

    final data = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Actualizar tarea' : 'Agregar tarea'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la tarea',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    title = value;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    description = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                final cleanTitle = title.trim();

                final cleanDescription = description.trim();

                if (cleanTitle.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop({'title': cleanTitle, 'description': cleanDescription});
              },
              icon: Icon(isEditing ? Icons.save : Icons.add),
              label: Text(isEditing ? 'Actualizar' : 'Guardar'),
            ),
          ],
        );
      },
    );

    if (data == null || !mounted) {
      return;
    }

    final cleanTitle = data['title'] ?? '';

    final cleanDescription = data['description'] ?? '';

    try {
      if (isEditing && task.id != null) {
        await _taskRepository.updateTask(
          id: task.id!,
          title: cleanTitle,
          description: cleanDescription,
          status: task.status,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea actualizada correctamente')),
        );
      } else {
        final sent = await _taskRepository.createTask(
          title: cleanTitle,
          description: cleanDescription,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sent
                  ? 'Tarea enviada al servidor'
                  : 'Sin conexión: tarea guardada en cola pendiente',
            ),
          ),
        );
      }

      if (!mounted) return;

      await _loadTasks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id == null) {
      return;
    }

    try {
      await _taskRepository.deleteTask(task.id!);

      await _loadTasks();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tarea eliminada')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Para esta entrega, eliminar requiere conexión.'),
        ),
      );
    }
  }

  Future<void> _syncNow() async {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sincronizando...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await _taskRepository.syncPending();

      await _loadTasks();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronización finalizada')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible sincronizar en este momento'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await SecureStorageService.deleteTokens();

    await _taskRepository.clearLocalData();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Widget _statusBanner() {
    final text = _fromCache
        ? 'MODO SIN CONEXIÓN · Datos locales ${_ageText()}'
        : 'En línea · Última sincronización ${_ageText()}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(_fromCache ? Icons.cloud_off : Icons.cloud_done),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          if (_pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Text('Pendientes: $_pendingCount'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskManager'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: _loading ? null : _syncNow,
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          _statusBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : AsyncState<Task>(
                    loading: false,
                    error: null,
                    items: _tasks,
                    emptyWidget: const Center(
                      child: Text('No hay tareas almacenadas.'),
                    ),
                    itemBuilder: (context, task) {
                      return TaskCard(
                        title: task.title,
                        description: task.description.isEmpty
                            ? 'Sin descripción'
                            : task.description,
                        onEdit: _fromCache
                            ? null
                            : () {
                                _saveTask(task: task);
                              },
                        onDelete: _fromCache
                            ? null
                            : () {
                                _deleteTask(task);
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading
            ? null
            : () {
                _saveTask();
              },
        icon: const Icon(Icons.add),
        label: const Text('Agregar tarea'),
      ),
    );
  }
}
