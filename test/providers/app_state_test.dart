import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio falso: evita red y devuelve una lista fija.
class _FakeApi extends SheetsApiService {
  final List<JobApplication> data;

  _FakeApi(this.data) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;
}

void main() {
  final apps = [
    JobApplication(
      rowIndex: 1,
      empresa: 'A',
      estado: 'Enviada',
      porGestionar: true,
      fechaPostulacion: '01/01/2026',
    ),
    JobApplication(
      rowIndex: 2,
      empresa: 'B',
      estado: 'Aceptada',
      fechaPostulacion: '02/01/2026',
    ),
    JobApplication(
      rowIndex: 3,
      empresa: 'C',
      estado: 'Rechazada',
      fechaPostulacion: '03/01/2026',
    ),
    JobApplication(
      rowIndex: 4,
      empresa: 'D',
      estado: 'Retirada',
      fechaPostulacion: '04/01/2026',
    ),
    JobApplication(
      rowIndex: 5,
      empresa: 'E',
      estado: 'En revisión',
      entrevistaRealizada: true,
      fechaPostulacion: '05/01/2026',
    ),
  ];

  Future<AppState> build() async {
    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);
    return state;
  }

  test('dashboardStats: finalizadas = rechazada+retirada+aceptada y cuenta porGestionar', () async {
    final stats = (await build()).dashboardStats;
    expect(stats.total, 5);
    expect(stats.finalizadas, 3);
    expect(stats.porGestionar, 1);
    expect(stats.entrevistas, 1);
    // Solo 'E' queda activa: 'A' es enviada, 'B' aceptada, 'C'/'D' terminales.
    expect(stats.activas, 1);
  });

  test('activas excluye aceptada; onlyRejected la incluye', () async {
    final state = await build();

    final activas = state.getApplications('activas').map((a) => a.rowIndex).toList();
    expect(activas, isNot(contains(2)));
    expect(activas, equals([5]));

    final finalizadas =
        state.getApplications('onlyRejected').map((a) => a.rowIndex).toList();
    expect(finalizadas, containsAll([2, 3, 4]));
  });

  test('porGestionar filtra solo las marcadas', () async {
    final only = (await build()).getApplications('porGestionar');
    expect(only.map((a) => a.rowIndex), equals([1]));
  });

  test('las marcadas porGestionar se ordenan primero en cualquier listado', () async {
    final all = (await build()).getApplications('all');
    expect(all.first.rowIndex, 1);
    expect(all.first.porGestionar, isTrue);
  });
}
