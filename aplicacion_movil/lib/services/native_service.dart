import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Resultado de una operación nativa.
///
/// Permite que la interfaz conozca si la capacidad:
/// - funcionó,
/// - fue denegada,
/// - fue denegada permanentemente,
/// - no está disponible,
/// - o produjo un error.
class NativeResult<T> {
  final bool success;
  final T? data;
  final String message;
  final bool permanentlyDenied;

  const NativeResult({
    required this.success,
    this.data,
    required this.message,
    this.permanentlyDenied = false,
  });
}

/// Servicio de funcionalidades nativas - Semana 14.
///
/// Capacidades:
/// 1. Cámara.
/// 2. Ubicación.
///
/// Los permisos NO se solicitan al iniciar la aplicación.
/// Se solicitan únicamente cuando el usuario intenta utilizar
/// la funcionalidad correspondiente.
class NativeService {
  NativeService._();

  static final NativeService instance = NativeService._();

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // CÁMARA
  // ============================================================

  Future<NativeResult<XFile>> takePhoto() async {
    try {
      // En Android solicitamos explícitamente CAMERA.
      if (Platform.isAndroid) {
        var status = await ph.Permission.camera.status;

        if (status.isPermanentlyDenied || status.isRestricted) {
          return const NativeResult(
            success: false,
            message: 'El acceso a la cámara está bloqueado. Habilítalo desde los ajustes del dispositivo.',
            permanentlyDenied: true,
          );
        }

        if (!status.isGranted) {
          status = await ph.Permission.camera.request();
        }

        if (status.isPermanentlyDenied || status.isRestricted) {
          return const NativeResult(
            success: false,
            message: 'El permiso de cámara fue bloqueado permanentemente. Puedes habilitarlo desde Ajustes.',
            permanentlyDenied: true,
          );
        }

        if (!status.isGranted) {
          return const NativeResult(
            success: false,
            message: 'Permiso de cámara denegado. La tarea puede continuar sin fotografía.',
          );
        }
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null) {
        return const NativeResult(
          success: false,
          message: 'No se tomó ninguna fotografía.',
        );
      }

      return NativeResult(
        success: true,
        data: photo,
        message: 'Fotografía capturada correctamente.',
      );
    } catch (e) {
      return NativeResult(
        success: false,
        message: 'No fue posible utilizar la cámara: $e',
      );
    }
  }

  // ============================================================
  // UBICACIÓN
  // ============================================================

  Future<NativeResult<Position>> getCurrentLocation() async {
    try {
      // Primero comprobamos el servicio GPS.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return const NativeResult(
          success: false,
          message: 'La ubicación del dispositivo está desactivada. Activa el GPS para utilizar esta función.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const NativeResult(
          success: false,
          message: 'Permiso de ubicación denegado. Puedes continuar usando la aplicación sin ubicación.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const NativeResult(
          success: false,
          message: 'El permiso de ubicación está denegado permanentemente. Habilítalo desde Ajustes.',
          permanentlyDenied: true,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return NativeResult(
        success: true,
        data: position,
        message: 'Ubicación obtenida correctamente.',
      );
    } catch (e) {
      return NativeResult(
        success: false,
        message: 'No fue posible obtener la ubicación: $e',
      );
    }
  }

  // ============================================================
  // AJUSTES
  // ============================================================

  Future<bool> openAppSettings() async {
    return ph.openAppSettings();
  }

  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }
}
