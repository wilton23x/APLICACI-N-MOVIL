import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AsyncState<T> extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? emptyWidget;
  final VoidCallback? onRetry;

  const AsyncState({
    super.key,
    required this.loading,
    required this.error,
    required this.items,
    required this.itemBuilder,
    this.emptyWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Estado: cargando
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado: error
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No se pudieron cargar los datos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Estado: vacío
    if (items.isEmpty) {
      return emptyWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48),
                  SizedBox(height: AppSpacing.md),
                  Text('No hay elementos disponibles'),
                ],
              ),
            ),
          );
    }

    // Estado: datos disponibles
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index]);
      },
    );
  }
}
