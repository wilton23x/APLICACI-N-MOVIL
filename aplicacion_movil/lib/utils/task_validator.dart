class TaskValidator {
  TaskValidator._();

  static String? validateTitle(String? value) {
    final title = value?.trim() ?? '';

    if (title.isEmpty) {
      return 'El título es obligatorio';
    }

    if (title.length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }

    if (title.length > 100) {
      return 'El título no puede superar los 100 caracteres';
    }

    return null;
  }

  static String? validateDescription(String? value) {
    final description = value?.trim() ?? '';

    if (description.length > 500) {
      return 'La descripción no puede superar los 500 caracteres';
    }

    return null;
  }

  static bool isValidTitle(String? value) {
    return validateTitle(value) == null;
  }

  static bool isValidDescription(String? value) {
    return validateDescription(value) == null;
  }
}