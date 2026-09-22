import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static const border = Color(0xFFBAE6FD);
  static const destructive = Color(0xFFDC2626);
  static const onDestructive = Color(0xFFFFFFFF);
  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFB45309);
  static const navDivider = Color(0xFFCBD5E1);
  static const chipBorder = Color(0xFFD8E2EE);
}

/// Flat Design tokens for DevJobs — dark theme (desaturated slate-blue).
abstract final class AppColorsDark {
  static const primary = Color(0xFF38BDF8);
  static const onPrimary = Color(0xFF082F49);
  static const secondary = Color(0xFF7DD3FC);
  static const onSecondary = Color(0xFF0F172A);
  static const accent = Color(0xFF4ADE80);
  static const onAccent = Color(0xFF052E16);
  static const background = Color(0xFF0F172A);
  static const foreground = Color(0xFFE2E8F0);
  static const card = Color(0xFF16233B);
  static const onCard = Color(0xFFE2E8F0);
  static const muted = Color(0xFF1E293B);
  static const onMuted = Color(0xFF94A3B8);
  static const border = Color(0xFF334155);
  static const destructive = Color(0xFFF87171);
  static const onDestructive = Color(0xFF450A0A);
  static const warning = Color(0xFFFBBF24);
  static const navDivider = Color(0xFF475569);
  static const chipBorder = Color(0xFF334155);
}

/// Semantic status colors — light variants.
abstract final class StatusColors {
  static const enviada = AppColors.primary;
  static const sinRespuesta = AppColors.warning;
  static const revision = Color(0xFFEA580C);
  static const entrevista = Color(0xFF7C3AED);
  static const entrevistaRealizada = Color(0xFF6D28D9);
  static const pruebaTecnica = Color(0xFF0D9488);
  static const oferta = AppColors.accent;
  static const aceptada = Color(0xFF22C55E);
  static const rechazada = AppColors.destructive;
  static const retirada = Color(0xFF64748B);
  static const otro = Color(0xFF94A3B8);
}

/// Semantic status colors — dark variants (lighter / desaturated).
abstract final class StatusColorsDark {
  static const enviada = AppColorsDark.primary;
  static const sinRespuesta = AppColorsDark.warning;
  static const revision = Color(0xFFFB923C);
  static const entrevista = Color(0xFFC4B5FD);
  static const entrevistaRealizada = Color(0xFFA78BFA);
  static const pruebaTecnica = Color(0xFF2DD4BF);
  static const oferta = AppColorsDark.accent;
  static const aceptada = Color(0xFF86EFAC);
  static const rechazada = AppColorsDark.destructive;
  static const retirada = Color(0xFF94A3B8);
  static const otro = Color(0xFF64748B);
}

Color statusColor(String status, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final s = status.trim().toLowerCase();
  if (s.contains('enviada')) {
    return dark ? StatusColorsDark.enviada : StatusColors.enviada;
  }
  if (s.contains('rechazada')) {
    return dark ? StatusColorsDark.rechazada : StatusColors.rechazada;
  }
  if (s == 'sin respuesta') {
    return dark ? StatusColorsDark.sinRespuesta : StatusColors.sinRespuesta;
  }
  if (s.contains('revisión') || s.contains('revision')) {
    return dark ? StatusColorsDark.revision : StatusColors.revision;
  }
  if (s == 'entrevista realizada') {
    return dark
        ? StatusColorsDark.entrevistaRealizada
        : StatusColors.entrevistaRealizada;
  }
  if (s.contains('entrevista')) {
    return dark ? StatusColorsDark.entrevista : StatusColors.entrevista;
  }
  if (s == 'prueba técnica' || s == 'prueba tecnica') {
    return dark ? StatusColorsDark.pruebaTecnica : StatusColors.pruebaTecnica;
  }
  if (s.contains('oferta')) {
    return dark ? StatusColorsDark.oferta : StatusColors.oferta;
  }
  if (s == 'aceptada') {
    return dark ? StatusColorsDark.aceptada : StatusColors.aceptada;
  }
  if (s == 'retirada') {
    return dark ? StatusColorsDark.retirada : StatusColors.retirada;
  }
  return dark ? StatusColorsDark.otro : StatusColors.otro;
}

Color pipelineColor(String label, Brightness brightness) {
  final key = switch (label) {
    'Sin respuesta' => 'sin respuesta',
    'En revisión' => 'revisión',
    'Prueba técnica' => 'prueba técnica',
    'Entrevista' => 'entrevista',
    'Oferta' => 'oferta',
    'Aceptada' => 'aceptada',
    'Enviada' => 'enviada',
    'Rechazada' => 'rechazada',
    'Retirada' => 'retirada',
    _ => '',
  };
  return statusColor(key, brightness);
}

/// Readable warning text color for the given brightness.
Color warningTextColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.warning : AppColors.warningDark;

/// Visible separator for the bottom navigation bar.
Color navDividerColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.navDivider : AppColors.navDivider;

/// Soft border for meta chips / badges.
Color chipBorderColor(Brightness brightness) =>
    brightness == Brightness.dark ? AppColorsDark.chipBorder : AppColors.chipBorder;

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          tertiary: AppColors.accent,
          onTertiary: AppColors.onAccent,
          error: AppColors.destructive,
          onError: AppColors.onDestructive,
          surface: AppColors.card,
          onSurface: AppColors.onCard,
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
          secondary: AppColorsDark.secondary,
          onSecondary: AppColorsDark.onSecondary,
          tertiary: AppColorsDark.accent,
          onTertiary: AppColorsDark.onAccent,
          error: AppColorsDark.destructive,
          onError: AppColorsDark.onDestructive,
          surface: AppColorsDark.card,
          onSurface: AppColorsDark.onCard,
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

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
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
          borderRadius: const BorderRadius.all(Radius.circular(16)),
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
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.primary : onMuted,
            );
          },
        ),
      ),
      dividerTheme: DividerThemeData(color: border),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}