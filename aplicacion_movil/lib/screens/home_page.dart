import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/async_state.dart';
import '../widgets/task_card.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TaskService _taskService;

  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _taskService = TaskService(token: widget.token);

    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tasks = await _taskService.getTasks();

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _saveTask({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');

    final descriptionController = TextEditingController(
      text: task?.description ?? '',
    );

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
                  textInputAction: TextInputAction.next,
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
                    labelText: 'DescripciÃ³n',
                    hintText: 'Escribe la descripciÃ³n',
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

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Escribe un nombre para la tarea'),
                    ),
                  );
                  return;
                }

                try {
                  if (isEditing && task.id != null) {
                    await _taskService.updateTask(
                      id: task.id!,
                      title: title,
                      description: description,
                      status: task.status,
                    );
                  } else {
                    await _taskService.createTask(
                      title: title,
                      description: description,
                    );
                  }

                  if (!context.mounted) return;

                  Navigator.pop(context, true);
                } catch (error) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
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

    if (result == true) {
      await _loadTasks();
    }
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id == null) return;

    try {
      await _taskService.deleteTask(task.id!);

      await _loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tarea eliminada')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 56, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No se pudieron cargar las tareas',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Reintentar',
                icon: Icons.refresh,
                onPressed: _loadTasks,
              ),
            ],
          ),
        ),
      );
    }

    return AsyncState<Task>(
      loading: false,
      error: null,
      items: _tasks,
      emptyWidget: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt, size: 56),
              SizedBox(height: AppSpacing.md),
              Text(
                'No hay tareas todavÃ­a',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Agrega una tarea para comenzar.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (context, task) {
        return TaskCard(
          title: task.title,
          description: task.description.isEmpty
              ? 'Sin descripciÃ³n'
              : task.description,
          onEdit: () => _saveTask(task: task),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TaskManager')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveTask(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar tarea'),
      ),
    );
  }
}
