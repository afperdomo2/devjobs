import 'dart:io';

import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio falso: evita red y devuelve una lista fija.
class _FakeApi extends SheetsApiService {
  List<JobApplication> data;

  int createCalls = 0;
  int fetchCalls = 0;
  int updateCalls = 0;
  JobApplication? lastCreated;
  int? lastUpdatedRow;
  Map<String, String>? lastUpdates;
  int nextRowIndex = 100;
  bool shiftedAfterCreate = true;
  bool failFetchAfterCreate = false;

  _FakeApi(List<JobApplication> data)
    : data = List.of(data),
      super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async {
    fetchCalls++;
    if (failFetchAfterCreate && createCalls > 0) {
      throw SocketException('offline');
    }
    return List.of(data);
  }

  @override
  Future<CreateResult> create(JobApplication application) async {
    createCalls++;
    lastCreated = application;

    final created = application.copyWith(rowIndex: nextRowIndex);
    if (shiftedAfterCreate) {
      for (var i = 0; i < data.length; i++) {
        if (data[i].rowIndex >= nextRowIndex) {
          data[i] = data[i].copyWith(rowIndex: data[i].rowIndex + 1);
        }
      }
      data.insert(0, created);
    } else {
      data.add(created);
    }

    return CreateResult(
      rowIndex: nextRowIndex,
      shifted: shiftedAfterCreate,
    );
  }

  @override
  Future<void> updateRow(int rowIndex, Map<String, String> updates) async {
    updateCalls++;
    lastUpdatedRow = rowIndex;
    lastUpdates = updates;
  }
}

/// Simula un dispositivo sin conexión desde el primer fetch.
class _OfflineApi extends SheetsApiService {
  _OfflineApi() : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async =>
      throw SocketException('offline');

  @override
  Future<CreateResult> create(JobApplication application) async =>
      throw StateError('create no debería llamarse sin conexión');
}

/// Fetch OK, pero la escritura falla por red.
class _CreateNetworkErrorApi extends _FakeApi {
  _CreateNetworkErrorApi(super.data);

  @override
  Future<CreateResult> create(JobApplication application) async =>
      throw SocketException('offline');
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

  test('createApplication con desplazamiento refresca la lista', () async {
    final api = _FakeApi(apps)
      ..nextRowIndex = 3
      ..shiftedAfterCreate = true;
    final state = AppState(apiService: api);
    await state.fetchApplications(forceRefresh: true);
    expect(api.fetchCalls, 1);

    var notified = 0;
    state.addListener(() => notified++);

    const draft = JobApplication(
      rowIndex: 0,
      empresa: 'Nueva',
      vacante: 'Dev',
      estado: 'Enviada',
      fechaPostulacion: '2026-11-04',
    );
    final created = await state.createApplication(draft);

    expect(api.createCalls, 1);
    expect(api.fetchCalls, 2); // refresco forzado tras el desplazamiento
    expect(created.rowIndex, 3);
    expect(
      state.applications.any((a) => a.empresa == 'Nueva' && a.rowIndex == 3),
      isTrue,
    );
    // Las filas 3, 4 y 5 se desplazan a 4, 5 y 6.
    expect(state.applications.firstWhere((a) => a.empresa == 'C').rowIndex, 4);
    expect(state.applications.firstWhere((a) => a.empresa == 'D').rowIndex, 5);
    expect(state.applications.firstWhere((a) => a.empresa == 'E').rowIndex, 6);
    // Las filas 1 y 2 no cambian.
    expect(state.applications.firstWhere((a) => a.empresa == 'A').rowIndex, 1);
    expect(state.applications.firstWhere((a) => a.empresa == 'B').rowIndex, 2);
    expect(notified, greaterThan(0));
  });

  test('createApplication con shift mantiene los índices si el refetch falla', () async {
    final api = _FakeApi(apps)
      ..nextRowIndex = 3
      ..shiftedAfterCreate = true
      ..failFetchAfterCreate = true;
    final state = AppState(apiService: api);
    await state.fetchApplications(forceRefresh: true);
    expect(api.fetchCalls, 1);

    const draft = JobApplication(
      rowIndex: 0,
      empresa: 'Nueva',
      vacante: 'Dev',
      fechaPostulacion: '2026-11-04',
    );
    final created = await state.createApplication(draft);

    expect(created.rowIndex, 3);
    expect(api.fetchCalls, 2);
    expect(state.offline, isTrue);
    // El refresh falló, pero el desplazamiento local mantiene los índices.
    expect(
      state.applications.any((a) => a.empresa == 'Nueva' && a.rowIndex == 3),
      isTrue,
    );
    expect(state.applications.firstWhere((a) => a.empresa == 'C').rowIndex, 4);
    expect(state.applications.firstWhere((a) => a.empresa == 'D').rowIndex, 5);
    expect(state.applications.firstWhere((a) => a.empresa == 'E').rowIndex, 6);
  });

  test('createApplication sin desplazamiento inserta local y no refresca', () async {
    final api = _FakeApi([
      JobApplication(
        rowIndex: 14,
        empresa: 'Consultec',
        vacante: 'Backend',
        fechaPostulacion: '01/11/2026',
      ),
      JobApplication(
        rowIndex: 15,
        empresa: 'Rappi',
        vacante: 'Mobile',
        fechaPostulacion: '02/11/2026',
      ),
    ])
      ..nextRowIndex = 13
      ..shiftedAfterCreate = false;
    final state = AppState(apiService: api);
    await state.fetchApplications(forceRefresh: true);
    expect(api.fetchCalls, 1);

    const draft = JobApplication(
      rowIndex: 0,
      empresa: 'Nueva',
      vacante: 'Dev',
      fechaPostulacion: '2026-11-04',
    );
    final created = await state.createApplication(draft);

    expect(created.rowIndex, 13);
    expect(api.fetchCalls, 1); // no hubo refresh
    expect(
      state.applications.any((a) => a.empresa == 'Nueva' && a.rowIndex == 13),
      isTrue,
    );
    expect(
      state.applications.firstWhere((a) => a.empresa == 'Consultec').rowIndex,
      14,
    );
    expect(
      state.applications.firstWhere((a) => a.empresa == 'Rappi').rowIndex,
      15,
    );
  });

  test('createApplication sin conexión no llama a la API', () async {
    final state = AppState(apiService: _OfflineApi());
    await state.fetchApplications(forceRefresh: true);
    expect(state.offline, isTrue);

    const draft = JobApplication(rowIndex: 0, empresa: 'X', vacante: 'Y');
    await expectLater(
      state.createApplication(draft),
      throwsA(isA<Exception>()),
    );
  });

  test('createApplication marca offline y no inserta si falla la red', () async {
    final api = _CreateNetworkErrorApi(apps);
    final state = AppState(apiService: api);
    await state.fetchApplications(forceRefresh: true);
    expect(state.offline, isFalse);

    const draft = JobApplication(rowIndex: 0, empresa: 'X', vacante: 'Y');
    await expectLater(
      state.createApplication(draft),
      throwsA(isA<Exception>()),
    );

    expect(state.offline, isTrue);
    expect(state.applications.length, apps.length);
  });

  test('updateApplication también parchea las fechas', () async {
    final api = _FakeApi(apps);
    final state = AppState(apiService: api);
    await state.fetchApplications(forceRefresh: true);

    await state.updateApplication(1, {
      'fechaPostulacion': '2026-12-25',
      'fechaSeguimiento': '2026-12-31',
    });

    final updated = state.applications.firstWhere((a) => a.rowIndex == 1);
    expect(updated.fechaPostulacion, '2026-12-25');
    expect(updated.fechaSeguimiento, '2026-12-31');
    expect(api.lastUpdatedRow, 1);

    await state.updateApplication(1, {'fechaSeguimiento': ''});
    final cleared = state.applications.firstWhere((a) => a.rowIndex == 1);
    expect(cleared.fechaSeguimiento, '');
  });
}
