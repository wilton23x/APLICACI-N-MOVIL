// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: (json['id'] as num?)?.toInt(),
  title: json['titulo'] as String,
  description: json['descripcion'] as String? ?? '',
  photoPath: json['foto_path'] as String?,
  latitude: Task._toDouble(json['latitud']),
  longitude: Task._toDouble(json['longitud']),
  status: json['estado'] as String? ?? 'Pendiente',
  userId: (json['usuario_id'] as num?)?.toInt(),
  serverUpdatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'titulo': instance.title,
  'descripcion': instance.description,
  'foto_path': instance.photoPath,
  'latitud': instance.latitude,
  'longitud': instance.longitude,
  'estado': instance.status,
  'usuario_id': instance.userId,
  'updated_at': instance.serverUpdatedAt?.toIso8601String(),
};
