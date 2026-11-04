import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devjobs/theme.dart';

void main() {
  group('statusColor', () {
    test('mapea estados frecuentes en claro con valores text-safe', () {
      final b = Brightness.light;
      expect(statusColor('Enviada', b), StatusColors.enviada);
      expect(statusColor('Rechazada', b), StatusColors.rechazada);
      expect(statusColor('sin respuesta', b), StatusColors.sinRespuesta);
      expect(statusColor('aceptada', b), StatusColors.aceptada);
      expect(statusColor('retirada', b), StatusColors.retirada);
      expect(statusColor('Oferta recibida', b), StatusColors.oferta);
      expect(statusColor('Prueba técnica', b), StatusColors.pruebaTecnica);
      expect(statusColor('En revisión', b), StatusColors.revision);
    });

    test('los colores de texto cumplen contraste mínimo sobre blanco', () {
      // AA para texto normal (4.5:1) sobre blanco puro.
      for (final c in [
        StatusColors.enviada,
        StatusColors.sinRespuesta,
        StatusColors.revision,
        StatusColors.entrevista,
        StatusColors.pruebaTecnica,
        StatusColors.oferta,
        StatusColors.aceptada,
        StatusColors.rechazada,
        StatusColors.retirada,
      ]) {
        final lum = _relativeLuminance(c);
        final ratio = 1.05 / (lum + 0.05);
        expect(ratio, greaterThan(4.5),
            reason:
                'color #${c.toARGB32().toRadixString(16)} no llega a 4.5:1');
      }
    });

    test('insensible a mayúsculas, espacios y acentos', () {
      final b = Brightness.light;
      expect(statusColor('  ENVIADA  ', b), StatusColors.enviada);
      expect(statusColor('RechAzada', b), StatusColors.rechazada);
      expect(statusColor('Aceptada', b), StatusColors.aceptada);
      expect(statusColor('en revision', b), StatusColors.revision);
      expect(statusColor('prueba tecnica', b), StatusColors.pruebaTecnica);
    });

    test('entrevista agendada y realizada comparten color (los separa el icono)',
        () {
      final b = Brightness.light;
      expect(statusColor('entrevista agendada', b), StatusColors.entrevista);
      expect(
          statusColor('Entrevista realizada', b), StatusColors.entrevista);
      expect(statusColor('Entrevista', b), StatusColors.entrevista);
      expect(statusColor('entrevista agendada', b),
          statusColor('Entrevista realizada', b));
    });

    test('aceptada y oferta usan colores distintos (van juntas en el pipeline)',
        () {
      final b = Brightness.light;
      expect(statusColor('aceptada', b), isNot(statusColor('oferta', b)));
      final dark = Brightness.dark;
      expect(
          statusColor('aceptada', dark), isNot(statusColor('oferta', dark)));
    });

    test('reconoce por prefijo variantes reales', () {
      final b = Brightness.light;
      expect(statusColor('Oferta laboral', b), StatusColors.oferta);
      expect(statusColor('Entrevista inicial', b), StatusColors.entrevista);
      expect(
          statusColor('Prueba técnica: katas', b), StatusColors.pruebaTecnica);
    });

    test('cadena vacía o desconocida retorna otro', () {
      final b = Brightness.light;
      expect(statusColor('', b), StatusColors.otro);
      expect(statusColor('   ', b), StatusColors.otro);
      expect(statusColor('estado inexistente', b), StatusColors.otro);
      expect(statusColor('reenviada', b), StatusColors.otro);
    });

    test('en oscuro devuelve variantes más claras', () {
      final dark = Brightness.dark;
      expect(statusColor('Entrevista', dark), StatusColorsDark.entrevista);
      expect(statusColor('Rechazada', dark), StatusColorsDark.rechazada);
      expect(statusColor('sin respuesta', dark), StatusColorsDark.sinRespuesta);
      expect(
          statusColor('Prueba técnica', dark), StatusColorsDark.pruebaTecnica);
      expect(statusColor('aceptada', dark), StatusColorsDark.aceptada);
      expect(statusColor('retirada', dark), StatusColorsDark.retirada);
      expect(statusColor('', dark), StatusColorsDark.otro);
    });
  });

  group('pipelineColor', () {
    test('mapea etiquetas del pipeline en ambos modos', () {
      expect(pipelineColor('Entrevista', Brightness.light),
          StatusColors.entrevista);
      expect(pipelineColor('Entrevista', Brightness.dark),
          StatusColorsDark.entrevista);
      expect(pipelineColor('Rechazada', Brightness.light),
          StatusColors.rechazada);
      expect(pipelineColor('Otros', Brightness.dark), StatusColorsDark.otro);
    });
  });

  group('colores semánticos', () {
    test('info, teal, success, neutral, indigo cambian con el brillo', () {
      expect(infoColor(Brightness.light), AppColors.info);
      expect(infoColor(Brightness.dark), AppColorsDark.info);
      expect(tealColor(Brightness.light), AppColors.teal);
      expect(tealColor(Brightness.dark), AppColorsDark.teal);
      expect(successColor(Brightness.light), AppColors.success);
      expect(successColor(Brightness.dark), AppColorsDark.success);
      expect(neutralColor(Brightness.light), AppColors.neutral);
      expect(neutralColor(Brightness.dark), AppColorsDark.neutral);
      expect(indigoColor(Brightness.light), AppColors.indigo);
      expect(indigoColor(Brightness.dark), AppColorsDark.indigo);
      expect(dangerColor(Brightness.light), AppColors.destructive);
    });
  });

  group('warningTextColor', () {
    test('usa ámbar oscuro en claro y ámbar claro en oscuro', () {
      expect(warningTextColor(Brightness.light), AppColors.warningDark);
      expect(warningTextColor(Brightness.dark), AppColorsDark.warning);
    });
  });

  group('warningContainer', () {
    test('el tinte cambia con el brillo y usa alfa 12%', () {
      final light = warningContainer(Brightness.light);
      expect(light.a, moreOrLessEquals(0.12, epsilon: 0.005));
      // Conserva el RGB del ámbar de tinte (solo cambia el alfa).
      expect(light.r, moreOrLessEquals(AppColors.warning.r, epsilon: 0.02));
      final dark = warningContainer(Brightness.dark);
      expect(dark.a, moreOrLessEquals(0.12, epsilon: 0.005));
      expect(dark.r, moreOrLessEquals(AppColorsDark.warning.r, epsilon: 0.02));
      // En claro el tinte es el ámbar intenso; en oscuro, el ámbar claro.
      expect(light.r, isNot(moreOrLessEquals(dark.r, epsilon: 0.02)));
    });
  });

  group('navDividerColor', () {
    test('usa gris claro visible en claro y gris medio en oscuro', () {
      expect(navDividerColor(Brightness.light), AppColors.navDivider);
      expect(navDividerColor(Brightness.dark), AppColorsDark.navDivider);
    });
  });

  group('chipBorderColor', () {
    test('usa borde suave claro en claro y slate en oscuro', () {
      expect(chipBorderColor(Brightness.light), AppColors.chipBorder);
      expect(chipBorderColor(Brightness.dark), AppColorsDark.chipBorder);
    });
  });

  group('borde de card', () {
    test('el borde de card es visible (>=3:1 sobre blanco en claro)', () {
      final ratio = 1.05 / (_relativeLuminance(AppColors.border) + 0.05);
      expect(ratio, greaterThan(3.0));
      expect(AppColorsDark.border, isNot(AppColorsDark.background));
    });
  });
}

/// WCAG relative luminance.
double _relativeLuminance(Color c) {
  double channel(double v) {
    final s = v;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}
