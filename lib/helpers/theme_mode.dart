import 'package:flutter/material.dart';

/// Nombre estable con el que se persiste [ThemeMode] en SharedPreferences.
///
/// No se usa `ThemeMode.name` directamente para que un cambio de versión de
/// Flutter no altere el valor guardado.
String themeModeName(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
  ThemeMode.system => 'system',
};

/// Convierte el valor persistido en un [ThemeMode].
///
/// Cualquier valor ausente o desconocido cae en [ThemeMode.system], que es el
/// comportamiento por defecto de la app.
ThemeMode themeModeFromName(String? name) => switch (name) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

/// Etiqueta visible en el menú de ajustes.
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'Claro',
  ThemeMode.dark => 'Oscuro',
  ThemeMode.system => 'Sistema',
};

/// Texto secundario que explica qué hace cada opción.
String themeModeDescription(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'Siempre con fondo claro',
  ThemeMode.dark => 'Siempre con fondo oscuro',
  ThemeMode.system => 'Sigue la configuración del dispositivo',
};

/// Ícono que acompaña cada opción.
IconData themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
  ThemeMode.system => Icons.brightness_auto_outlined,
};
