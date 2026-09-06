import 'package:flutter/material.dart';

import '../database/local_database.dart';
import '../models/task.dart';
import '../services/secure_storage_service.dart';
import '../services/sync_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/async_state.dart';
import '../widgets/task_card.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TaskService _taskService = const TaskService();
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
    setState(() => _loading = true);
    final result = await _taskService.getTasksOfflineFirst();
    final pending = await LocalDatabase.instance.pendingCount();
    if (!mounted) return;
    setState(() {
      _tasks = result.tasks;
      _fromCache = result.fromCache;
      _lastSyncAt = result.lastSyncAt;
      _pendingCount = pending;
      _loading = false;
    });
  }

  String _ageText() {
    if (_lastSyncAt == null) return 'sin sincronización previa';
    final diff = DateTime.now().toUtc().difference(_lastSyncAt!.toUtc());
    if (diff.inMinutes < 1) return 'hace menos de 1 minuto';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} días';
  }

  Future<void> _saveTask({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(text: task?.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isEditing = task != null;
        return AlertDialog(
          title: Text(isEditing ? 'Actualizar tarea' : 'Agregar tarea'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la tarea',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              label: isEditing ? 'Actualizar' : 'Guardar',
              icon: isEditing ? Icons.save : Icons.add,
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                if (title.isEmpty) return;
                try {
                  if (isEditing && task.id != null) {
                    await _taskService.updateTask(
                      id: task.id!,
                      title: title,
                      description: description,
                      status: task.status,
                    );
                  } else {
                    final sent = await _taskService.createTaskOfflineFirst(
                      title: title,
                      description: description,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sent
                            ? 'Tarea enviada al servidor'
                            : 'Sin conexión: tarea guardada en cola pendiente'),
                      ),
                    );
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    if (result == true) await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id == null) return;
    try {
      await _taskService.deleteTask(task.id!);
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Para esta entrega, eliminar requiere conexión.')),
      );
    }
  }

  Future<void> _syncNow() async {
    await SyncService.instance.processPendingQueue();
    await _loadTasks();
  }

  Future<void> _logout() async {
    await SecureStorageService.deleteToken();
    await LocalDatabase.instance.clearAll();
    if (!mounted) return;
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(_fromCache ? Icons.cloud_off : Icons.cloud_done),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          if (_pendingCount > 0) Text('Pendientes: $_pendingCount'),
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
            onPressed: _syncNow,
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
                    emptyWidget: const Center(child: Text('No hay tareas almacenadas.')),
                    itemBuilder: (context, task) => TaskCard(
                      title: task.title,
                      description: task.description.isEmpty ? 'Sin descripción' : task.description,
                      onEdit: _fromCache ? null : () => _saveTask(task: task),
                      onDelete: _fromCache ? null : () => _deleteTask(task),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveTask(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar tarea'),
      ),
    );
  }
}
