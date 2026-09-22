import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Flat Design tokens for DevJobs.
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
}

/// Semantic status colors mapped to the flat palette.
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

Color statusColor(String status) {
  final s = status.trim().toLowerCase();
  if (s.contains('enviada')) return StatusColors.enviada;
  if (s.contains('rechazada')) return StatusColors.rechazada;
  if (s == 'sin respuesta') return StatusColors.sinRespuesta;
  if (s.contains('revisión') || s.contains('revision')) return StatusColors.revision;
  if (s == 'entrevista realizada') return StatusColors.entrevistaRealizada;
  if (s.contains('entrevista')) return StatusColors.entrevista;
  if (s == 'prueba técnica' || s == 'prueba tecnica') return StatusColors.pruebaTecnica;
  if (s.contains('oferta')) return StatusColors.oferta;
  if (s == 'aceptada') return StatusColors.aceptada;
  if (s == 'retirada') return StatusColors.retirada;
  return StatusColors.otro;
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
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
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.foreground,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.muted,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.onMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.onMuted,
            );
          },
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}