class Task {
  final int? id;
  final String title;
  final String description;
  final String status;
  final int? userId;
  final DateTime? serverUpdatedAt;

  const Task({
    this.id,
    required this.title,
    required this.description,
    this.status = 'Pendiente',
    this.userId,
    this.serverUpdatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: int.tryParse(json['id']?.toString() ?? ''),
      title: json['titulo']?.toString() ?? '',
      description: json['descripcion']?.toString() ?? '',
      status: json['estado']?.toString() ?? 'Pendiente',
      userId: int.tryParse(json['usuario_id']?.toString() ?? ''),
      serverUpdatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  factory Task.fromLocalMap(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as int?,
      title: row['titulo']?.toString() ?? '',
      description: row['descripcion']?.toString() ?? '',
      status: row['estado']?.toString() ?? 'Pendiente',
      userId: row['usuario_id'] as int?,
      serverUpdatedAt: DateTime.tryParse(row['server_updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': title,
        'descripcion': description,
        'estado': status,
        'usuario_id': userId,
        'updated_at': serverUpdatedAt?.toUtc().toIso8601String(),
      };
}
