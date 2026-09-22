import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devjobs/theme.dart';

void main() {
  group('statusColor', () {
    test('mapea estados frecuentes en claro', () {
      final b = Brightness.light;
      expect(statusColor('Enviada', b), StatusColors.enviada);
      expect(statusColor('Rechazada', b), StatusColors.rechazada);
      expect(statusColor('sin respuesta', b), StatusColors.sinRespuesta);
      expect(statusColor('aceptada', b), StatusColors.aceptada);
      expect(statusColor('retirada', b), StatusColors.retirada);
    });

    test('insensible a mayúsculas y espacios', () {
      final b = Brightness.light;
      expect(statusColor('  ENVIADA  ', b), StatusColors.enviada);
      expect(statusColor('RechAzada', b), StatusColors.rechazada);
      expect(statusColor('Aceptada', b), StatusColors.aceptada);
    });

    test('distingue entrevista agendada vs realizada', () {
      final b = Brightness.light;
      expect(statusColor('entrevista agendada', b), StatusColors.entrevista);
      expect(
          statusColor('Entrevista realizada', b), StatusColors.entrevistaRealizada);
      expect(statusColor('Entrevista', b), StatusColors.entrevista);
    });

    test('reconocimiento por contiene (revisión, prueba, oferta)', () {
      final b = Brightness.light;
      expect(statusColor('En revisión', b), StatusColors.revision);
      expect(statusColor('en revision', b), StatusColors.revision);
      expect(statusColor('Prueba técnica', b), StatusColors.pruebaTecnica);
      expect(statusColor('prueba tecnica', b), StatusColors.pruebaTecnica);
      expect(statusColor('Oferta laboral', b), StatusColors.oferta);
    });

    test('cadena vacía o desconocida retorna otro', () {
      final b = Brightness.light;
      expect(statusColor('', b), StatusColors.otro);
      expect(statusColor('   ', b), StatusColors.otro);
      expect(statusColor('estado inexistente', b), StatusColors.otro);
    });

    test('en oscuro devuelve variantes más claras', () {
      final dark = Brightness.dark;
      expect(statusColor('Entrevista', dark), StatusColorsDark.entrevista);
      expect(statusColor('Rechazada', dark), StatusColorsDark.rechazada);
      expect(statusColor('sin respuesta', dark), StatusColorsDark.sinRespuesta);
      expect(statusColor('Prueba técnica', dark), StatusColorsDark.pruebaTecnica);
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

  group('warningTextColor', () {
    test('usa ámbar oscuro en claro y ámbar claro en oscuro', () {
      expect(warningTextColor(Brightness.light), AppColors.warningDark);
      expect(warningTextColor(Brightness.dark), AppColorsDark.warning);
    });
  });
}