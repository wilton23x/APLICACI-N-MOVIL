import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final int? id;

  @JsonKey(name: 'titulo')
  final String title;

  @JsonKey(name: 'descripcion', defaultValue: '')
  final String description;

  @JsonKey(name: 'foto_path')
  final String? photoPath;

  @JsonKey(name: 'latitud', fromJson: _toDouble)
  final double? latitude;

  @JsonKey(name: 'longitud', fromJson: _toDouble)
  final double? longitude;

  @JsonKey(name: 'estado')
  final String status;

  @JsonKey(name: 'usuario_id')
  final int? userId;

  @JsonKey(name: 'updated_at')
  final DateTime? serverUpdatedAt;

  const Task({
    this.id,
    required this.title,
    required this.description,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.status = 'Pendiente',
    this.userId,
    this.serverUpdatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  factory Task.fromLocalMap(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as int?,
      title: row['titulo']?.toString() ?? '',
      description: row['descripcion']?.toString() ?? '',
      photoPath: row['foto_path']?.toString(),
      latitude: _toDouble(row['latitud']),
      longitude: _toDouble(row['longitud']),
      status: row['estado']?.toString() ?? 'Pendiente',
      userId: row['usuario_id'] as int?,
      serverUpdatedAt: DateTime.tryParse(
        row['server_updated_at']?.toString() ?? '',
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}


