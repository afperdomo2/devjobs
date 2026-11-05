import 'package:flutter/material.dart';

import 'helpers/status.dart';

/// Flat Design tokens for DevJobs — light theme.
abstract final class AppColors {
  static const primary = Color(0xFF0369A1);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF0EA5E9);
  static const onSecondary = Color(0xFF0F172A);
  static const accent = Color(0xFF16A34A);
  static const onAccent = Color(0xFFFFFFFF);
  static const background = Color(0xFFF0F9FF);
  static const foreground = Color(0xFF0C4A6E);
  static const card = Color(0xFFFFFFFF);
  static const onCard = Color(0xFF0C4A6E);
  static const muted = Color(0xFFE7EFF5);
  static const onMuted = Color(0xFF475569);
  static const border = Color(0xFF5E85A1);
  static const destructive = Color(0xFFDC2626);
  static const onDestructive = Color(0xFFFFFFFF);

  /// Ámbar de relleno/tinte. NO sirve como texto sobre blanco (~2:1);
  /// para texto usar [warningDark].
  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFB45309);
  static const gestion = Color(0xFFC026D3);
  static const navDivider = Color(0xFFCBD5E1);
  static const chipBorder = Color(0xFFD8E2EE);

  // ---- Semantic text-safe colors (WCAG AA on white / on card) ----
  static const info = Color(0xFF0369A1);
  static const teal = Color(0xFF0F766E);
  static const success = Color(0xFF15803D);
  static const neutral = Color(0xFF475569);
  static const indigo = Color(0xFF4338CA);
}

/// Flat Design tokens for DevJobs — dark theme (desaturated slate-blue).
abstract final class AppColorsDark {
  static const primary = Color(0xFF38BDF8);
  static const onPrimary = Color(0xFF082F49);
  static const secondary = Color(0xFF2DD4BF);
  static const onSecondary = Color(0xFF042F2E);
  static const accent = Color(0xFF4ADE80);
  static const onAccent = Color(0xFF052E16);
  static const background = Color(0xFF0F172A);
  static const foreground = Color(0xFFE2E8F0);
  static const card = Color(0xFF16233B);
  static const onCard = Color(0xFFE2E8F0);
  static const muted = Color(0xFF1E293B);
  static const onMuted = Color(0xFF94A3B8);
  static const border = Color(0xFF64748B);
  static const destructive = Color(0xFFF87171);
  static const onDestructive = Color(0xFF450A0A);
  static const warning = Color(0xFFFBBF24);
  static const gestion = Color(0xFFE879F9);
  static const navDivider = Color(0xFF475569);
  static const chipBorder = Color(0xFF334155);

  // ---- Semantic text-safe colors (contrast against dark card) ----
  static const info = Color(0xFF38BDF8);
  static const teal = Color(0xFF2DD4BF);
  static const success = Color(0xFF4ADE80);
  static const neutral = Color(0xFF94A3B8);
  static const indigo = Color(0xFFA5B4FC);
}

/// Semantic status colors — light variants (text-safe).
abstract final class StatusColors {
  static const enviada = AppColors.info;
  static const sinRespuesta = AppColors.warningDark;
  static const revision = Color(0xFFC2410C);
  static const entrevista = Color(0xFF6D28D9);
  static const pruebaTecnica = AppColors.teal;
  static const oferta = AppColors.success;
  static const aceptada = AppColors.indigo;
  static const rechazada = AppColors.destructive;
  static const retirada = AppColors.neutral;
  static const otro = Color(0xFF64748B);
}

/// Semantic status colors — dark variants.
abstract final class StatusColorsDark {
  static const enviada = AppColorsDark.info;
  static const sinRespuesta = AppColorsDark.warning;
  static const revision = Color(0xFFFB923C);
  static const entrevista = Color(0xFFC4B5FD);
  static const pruebaTecnica = AppColorsDark.teal;
  static const oferta = AppColorsDark.success;
  static const aceptada = AppColorsDark.indigo;
  static const rechazada = AppColorsDark.destructive;
  static const retirada = AppColorsDark.neutral;
  static const otro = Color(0xFF64748B);
}

/// Claves exactas de estado. Cualquier variante que *empiece* por una de
/// ellas ('Oferta laboral') hereda su color; nada se busca en medio de la
/// cadena, para que un estado nuevo no caiga en un color por casualidad.
const _statusKeys = <String, int>{
  'entrevista agendada': 1,
  'entrevista realizada': 1,
  'oferta recibida': 5,
  'prueba tecnica': 4,
  'sin respuesta': 2,
  'en revision': 3,
  'rechazada': 7,
  'entrevista': 1,
  'revision': 3,
  'aceptada': 6,
  'retirada': 8,
  'enviada': 0,
  'prueba': 4,
  'oferta': 5,
};

int _statusIndex(String status) {
  final s = normalizeStatus(status);
  if (s.isEmpty) return 9;
  if (_statusKeys.containsKey(s)) return _statusKeys[s]!;
  // Prefijo: 'oferta laboral', 'entrevista inicial', 'prueba tecnica katas'...
  final keys = _statusKeys.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final k in keys) {
    if (s.startsWith(k)) return _statusKeys[k]!;
  }
  return 9;
}

Color statusColor(String status, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  switch (_statusIndex(status)) {
    case 0:
      return dark ? StatusColorsDark.enviada : StatusColors.enviada;
    case 1:
      return dark ? StatusColorsDark.entrevista : StatusColors.entrevista;
    case 2:
      return dark
          ? StatusColorsDark.sinRespuesta
          : StatusColors.sinRespuesta;
    case 3:
      return dark ? StatusColorsDark.revision : StatusColors.revision;
    case 4:
      return dark
          ? StatusColorsDark.pruebaTecnica
          : StatusColors.pruebaTecnica;
    case 5:
      return dark ? StatusColorsDark.oferta : StatusColors.oferta;
    case 6:
      return dark ? StatusColorsDark.aceptada : StatusColors.aceptada;
    case 7:
      return dark ? StatusColorsDark.rechazada : StatusColors.rechazada;
    case 8:
      return dark ? StatusColorsDark.retirada : StatusColors.retirada;
    default:
      return dark ? StatusColorsDark.otro : StatusColors.otro;
  }
}

Color pipelineColor(String label, Brightness brightness) =>
    statusColor(label, brightness);

// ---- Semantic text colors (build one source of truth for text) ----

/// Azul informativo — texto seguro en ambos modos.
Color infoColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.info : AppColors.info;

/// Teal — números y acentos de métricas.
Color tealColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.teal : AppColors.teal;

/// Verde — éxito / positivos (más oscuro en claro para que el texto lea).
Color successColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.success : AppColors.success;

/// Índigo — "aceptada".
Color indigoColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.indigo : AppColors.indigo;

/// Rojo — solo errores y rechazadas.
Color dangerColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.destructive : AppColors.destructive;

/// Gris neutro — elementos "cerrados" o no destacados.
Color neutralColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.neutral : AppColors.neutral;

/// Readable warning text color for the given brightness.
Color warningTextColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.warning : AppColors.warningDark;

/// Warning background tint (banner offline). Uses the ink amber in light
/// and the light amber in dark, so the tint is visible in both modes.
Color warningContainer(Brightness brightness) {
  final c = brightness == Brightness.dark
      ? AppColorsDark.warning
      : AppColors.warning;
  return c.withValues(alpha: 0.12);
}

/// Accent color for the "Por gestionar" flag (tag + border + icon).
/// Deliberadamente distinto del ámbar de "estancado" para no confundir señales.
Color gestionColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.gestion : AppColors.gestion;

/// Visible separator for the bottom navigation bar.
Color navDividerColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.navDivider : AppColors.navDivider;

/// Soft border for meta chips / badges.
Color chipBorderColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.chipBorder : AppColors.chipBorder;

// --------------------------------------------------------------------
// Spacing / radius / icon scale — 4px base.
// --------------------------------------------------------------------

abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

abstract final class AppRadius {
  /// Barras de progreso.
  static const double bar = 4;

  /// Chips y tags.
  static const double chip = 8;

  /// Campos de texto y controles.
  static const double control = 12;

  /// Cards.
  static const double card = 16;
}

abstract final class AppIconSize {
  /// Dentro de un chip.
  static const double chip = 14;

  /// En una fila de datos.
  static const double row = 18;

  /// En una métrica / tarjeta pequeña.
  static const double metric = 20;
}

// --------------------------------------------------------------------
// Type scale — single source for headings and labels.
// --------------------------------------------------------------------

abstract final class AppType {
  static const fontFamily = 'PlusJakartaSans';

  /// Número grande de una métrica: 20 / w700.
  static TextStyle metric(BuildContext context) =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w700);

  /// Título de card (empresa / vacante): 15 / w700.
  static TextStyle cardTitle(BuildContext context) =>
      const TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

  /// Título de sección dentro de una card: 14 / w600.
  static TextStyle section(BuildContext context) => Theme.of(context)
      .textTheme
      .titleSmall!
      .copyWith(fontWeight: FontWeight.w600);

  /// Etiqueta secundaria (chips, leyendas): 12 / w500 / onSurfaceVariant.
  static TextStyle label(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium!
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
}

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: Color(0xFFE0F2FE),
          onPrimaryContainer: Color(0xFF0C4A6E),
          secondary: AppColors.teal,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFD3EDE8),
          onSecondaryContainer: Color(0xFF0C4A6E),
          tertiary: AppColors.success,
          onTertiary: AppColors.onAccent,
          error: AppColors.destructive,
          onError: AppColors.onDestructive,
          surface: AppColors.card,
          onSurface: AppColors.onCard,
          surfaceContainerLow: AppColors.card,
          surfaceContainer: AppColors.muted,
          surfaceContainerHigh: AppColors.muted,
          surfaceContainerHighest: AppColors.muted,
          onSurfaceVariant: AppColors.onMuted,
          outline: AppColors.border,
          outlineVariant: AppColors.muted,
        ),
        background: AppColors.background,
        foreground: AppColors.foreground,
        card: AppColors.card,
        muted: AppColors.muted,
        onMuted: AppColors.onMuted,
        border: AppColors.border,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: AppColorsDark.primary,
          onPrimary: AppColorsDark.onPrimary,
          primaryContainer: Color(0xFF0C4A6E),
          onPrimaryContainer: Color(0xFFE0F2FE),
          secondary: AppColorsDark.teal,
          onSecondary: Color(0xFF042F2E),
          secondaryContainer: Color(0xFF134E4A),
          onSecondaryContainer: Color(0xFFCCFBF1),
          tertiary: AppColorsDark.success,
          onTertiary: AppColorsDark.onAccent,
          error: AppColorsDark.destructive,
          onError: AppColorsDark.onDestructive,
          surface: AppColorsDark.card,
          onSurface: AppColorsDark.onCard,
          surfaceContainerLow: AppColorsDark.card,
          surfaceContainer: AppColorsDark.muted,
          surfaceContainerHigh: AppColorsDark.muted,
          surfaceContainerHighest: AppColorsDark.muted,
          onSurfaceVariant: AppColorsDark.onMuted,
          outline: AppColorsDark.border,
          outlineVariant: AppColorsDark.muted,
        ),
        background: AppColorsDark.background,
        foreground: AppColorsDark.foreground,
        card: AppColorsDark.card,
        muted: AppColorsDark.muted,
        onMuted: AppColorsDark.onMuted,
        border: AppColorsDark.border,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required Color foreground,
    required Color card,
    required Color muted,
    required Color onMuted,
    required Color border,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );

    final textTheme = base.textTheme.apply(fontFamily: AppType.fontFamily);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius:
              const BorderRadius.all(Radius.circular(AppRadius.card)),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: muted,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : onMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.primary : onMuted,
            );
          },
        ),
      ),
      // Campos de texto planos: relleno + radio, sin subrayado de M3.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: onMuted, fontSize: 14),
        labelStyle: TextStyle(color: onMuted, fontSize: 14),
        floatingLabelStyle: TextStyle(color: scheme.primary, fontSize: 14),
        border: _inputBorder(border: BorderSide.none),
        enabledBorder: _inputBorder(border: BorderSide.none),
        focusedBorder:
            _inputBorder(border: BorderSide(color: scheme.primary, width: 1.5)),
        errorBorder:
            _inputBorder(border: BorderSide(color: scheme.error, width: 1)),
        focusedErrorBorder: _inputBorder(
            border: BorderSide(color: scheme.error, width: 1.5)),
        disabledBorder: _inputBorder(border: BorderSide.none),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadius.control)),
          ),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadius.control)),
          ),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadius.control)),
          ),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0C4A6E),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              const BorderRadius.all(Radius.circular(AppRadius.control)),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(AppRadius.chip),
        thickness: WidgetStateProperty.all(6),
        thumbColor: WidgetStateProperty.all(
          onMuted.withValues(alpha: 0.45),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      // Evita el "borroso/gris" al navegar: el builder por defecto de M3
      // (ZoomPageTransitionsBuilder) rasteriza la página entrante y puede
      // dejar un frame gris/borroso que solo se repinta al repintar.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android:
              ZoomPageTransitionsBuilder(allowSnapshotting: false),
          TargetPlatform.iOS:
              ZoomPageTransitionsBuilder(allowSnapshotting: false),
          TargetPlatform.windows:
              ZoomPageTransitionsBuilder(allowSnapshotting: false),
          TargetPlatform.macOS:
              ZoomPageTransitionsBuilder(allowSnapshotting: false),
          TargetPlatform.linux:
              ZoomPageTransitionsBuilder(allowSnapshotting: false),
          TargetPlatform.fuchsia:
              ZoomPageTransitionsBuilder(allowSnapshotting: false),
        },
      ),
    );
  }

  static InputBorder _inputBorder({required BorderSide border}) {
    return OutlineInputBorder(
      borderRadius:
          const BorderRadius.all(Radius.circular(AppRadius.control)),
      borderSide: border,
    );
  }
}
