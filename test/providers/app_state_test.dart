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

  test('activas excluye aceptada; finalizadas la incluye', () async {
    final state = await build();

    final activas = state
        .getApplications(AppState.filterActivas)
        .map((a) => a.rowIndex)
        .toList();
    expect(activas, isNot(contains(2)));
    expect(activas, equals([5]));

    final finalizadas = state
        .getApplications(AppState.filterFinalizadas)
        .map((a) => a.rowIndex)
        .toList();
    expect(finalizadas, containsAll([2, 3, 4]));
  });

  test('porGestionar filtra solo las marcadas', () async {
    final only = (await build()).getApplications(AppState.filterPorGestionar);
    expect(only.map((a) => a.rowIndex), equals([1]));
  });

  test('las marcadas porGestionar se ordenan primero en cualquier listado', () async {
    final all = (await build()).getApplications(AppState.filterAll);
    expect(all.first.rowIndex, 1);
    expect(all.first.porGestionar, isTrue);
  });

  test('arranca en Inicio y con el filtro Todas', () async {
    final state = await build();
    expect(state.currentTab, AppState.tabInicio);
    expect(state.applicationsFilter, AppState.filterAll);
  });

  test('setApplicationsFilter cambia el filtro y solo notifica si cambió', () async {
    final state = await build();
    var notified = 0;
    state.addListener(() => notified++);

    state.setApplicationsFilter(AppState.filterActivas);
    expect(state.applicationsFilter, AppState.filterActivas);
    expect(state.currentTab, AppState.tabInicio);
    expect(notified, 1);

    state.setApplicationsFilter(AppState.filterActivas);
    expect(notified, 1);
  });

  test('openApplications salta a Postulaciones con el filtro indicado', () async {
    final state = await build();
    var notified = 0;
    state.addListener(() => notified++);

    state.openApplications(AppState.filterEnviadas);
    expect(state.currentTab, AppState.tabPostulaciones);
    expect(state.applicationsFilter, AppState.filterEnviadas);
    expect(notified, 1);
  });

  test('countApplications cuenta cada filtro', () async {
    final state = await build();
    expect(state.countApplications(AppState.filterAll), 5);
    expect(state.countApplications(AppState.filterActivas), 1);
    expect(state.countApplications(AppState.filterEnviadas), 1);
    expect(state.countApplications(AppState.filterFinalizadas), 3);
    expect(state.countApplications(AppState.filterPorGestionar), 1);

    final empty = AppState(apiService: _FakeApi([]));
    expect(empty.countApplications(AppState.filterAll), 0);
    expect(empty.countApplications(AppState.filterFinalizadas), 0);
  });
}
