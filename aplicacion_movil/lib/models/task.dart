class Task {
  final int? id;
  final String title;
  final String description;
  final String status;
  final int? userId;

  const Task({
    this.id,
    required this.title,
    required this.description,
    this.status = 'Pendiente',
    this.userId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['titulo']?.toString() ?? '',
      description: json['descripcion']?.toString() ?? '',
      status: json['estado']?.toString() ?? 'Pendiente',
      userId: json['usuario_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': title,
      'descripcion': description,
      'estado': status,
      'usuario_id': userId,
    };
  }
}
