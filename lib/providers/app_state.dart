import 'package:flutter/foundation.dart';

import '../helpers/application_sort.dart';
import '../helpers/network_error.dart';
import '../helpers/status.dart';
import '../models/job_application.dart';
import '../services/local_cache.dart';
import '../services/sheets_api_service.dart';

class AppState extends ChangeNotifier {
  final SheetsApiService apiService;
  final LocalCache? localCache;

  List<JobApplication>? _cached;
  DateTime? _lastFetched;
  bool _loading = false;
  String? _error;
  bool _offline = false;
  int _currentTab = tabInicio;
  String _applicationsFilter = filterAll;
  bool _cacheLoaded = false;

  static const _cacheTtl = Duration(minutes: 3);

  /// Índices de los destinos del `NavigationBar`. Centralizados para que
  /// reordenar las pestañas no dependa de números mágicos repartidos.
  static const tabInicio = 0;
  static const tabPostulaciones = 1;
  static const tabEmpresas = 2;
  static const tabAgenda = 3;

  /// Filtros de la pestaña Postulaciones.
  static const filterAll = 'all';
  static const filterActivas = 'activas';
  static const filterEnviadas = 'enviadas';
  static const filterFinalizadas = 'finalizadas';
  static const filterPorGestionar = 'porGestionar';

  AppState({required this.apiService, this.localCache});

  int get currentTab => _currentTab;
  String get applicationsFilter => _applicationsFilter;
  bool get loading => _loading;
  String? get error => _error;
  bool get offline => _offline;
  bool get isReadOnly => _offline;
  bool get hasData => _cached != null && _cached!.isNotEmpty;
  DateTime? get cacheTimestamp => localCache?.lastSavedAt;

  List<JobApplication> get applications => _cached ?? [];

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  /// Cambia el filtro de la pestaña Postulaciones sin mover de pestaña.
  void setApplicationsFilter(String filter) {
    if (_applicationsFilter == filter) return;
    _applicationsFilter = filter;
    notifyListeners();
  }

  /// Abre Postulaciones con el filtro indicado (atajos del dashboard).
  void openApplications(String filter) {
    _applicationsFilter = filter;
    _currentTab = tabPostulaciones;
    notifyListeners();
  }

  DashboardStats get dashboardStats {
    final apps = _cached;
    if (apps == null) {
      return const DashboardStats(
        total: 0,
        activas: 0,
        entrevistas: 0,
        conRespuesta: 0,
        finalizadas: 0,
        porGestionar: 0,
      );
    }
    return DashboardStats(
      total: apps.length,
      activas: apps.where((a) => _matchesFilter(a, filterActivas)).length,
      entrevistas: apps.where((a) => a.entrevistaRealizada).length,
      conRespuesta: apps.where((a) => hasResponse(a.estado)).length,
      finalizadas: apps.where((a) => _matchesFilter(a, filterFinalizadas)).length,
      porGestionar: apps.where((a) => a.porGestionar).length,
    );
  }

  List<JobApplication> getByField(String field, String value) {
    final v = value.trim().toLowerCase();
    final apps = (_cached ?? [])
        .where((a) {
          switch (field) {
            case 'ciudad':
              return a.ciudad.trim().toLowerCase() == v;
            case 'modalidad':
              return a.modalidad.trim().toLowerCase() == v;
            case 'plataforma':
              return a.plataforma.trim().toLowerCase() == v;
            case 'empresa':
              return a.empresa.trim().toLowerCase() == v;
            default:
              return false;
          }
        })
        .toList();
    return sortApplications(apps);
  }

  List<JobApplication> getApplications(String filterMode) {
    return sortApplications(
      (_cached ?? []).where((a) => _matchesFilter(a, filterMode)),
    );
  }

  /// Número de postulaciones de un filtro, sin ordenar ni copiar la lista.
  /// Lo usan los contadores de las pills de Postulaciones.
  int countApplications(String filterMode) =>
      (_cached ?? []).where((a) => _matchesFilter(a, filterMode)).length;

  bool _matchesFilter(JobApplication a, String filterMode) {
    switch (filterMode) {
      case filterActivas:
        return a.estado.trim().toLowerCase() != 'enviada' &&
            !_isTerminal(a.estado);
      case filterEnviadas:
        return a.estado.trim().toLowerCase() == 'enviada';
      case filterFinalizadas:
        return _isTerminal(a.estado);
      case filterPorGestionar:
        return a.porGestionar;
      default:
        return true;
    }
  }

  bool _isTerminal(String estado) => isTerminalStatus(estado);

  Future<void> updateApplication(int rowIndex, Map<String, String> updates) async {
    if (_offline) {
      throw Exception('Sin conexión a internet. No se puede editar en modo solo lectura.');
    }
    try {
      await apiService.updateRow(rowIndex, updates);
    } catch (e) {
      if (isNetworkError(e)) {
        _offline = true;
        notifyListeners();
      }
      throw Exception(friendlyErrorMessage(e));
    }

    if (_cached != null) {
      final index = _cached!.indexWhere((a) => a.rowIndex == rowIndex);
      if (index != -1) {
        final old = _cached![index];
        _cached![index] = old.copyWith(
          empresa: updates['empresa'],
          vacante: updates['vacante'],
          tipoContrato: updates['tipoContrato'],
          modalidad: updates['modalidad'],
          ciudad: updates['ciudad'],
          salarioOfrecido: updates['salarioOfrecido'],
          estado: updates['estado'],
          link: updates['link'],
          descripcion: updates['descripcion'],
          fechaPostulacion: updates['fechaPostulacion'],
          fechaSeguimiento: updates['fechaSeguimiento'],
          contacto: updates['contacto'],
          comentarios: updates['comentarios'],
          entrevistaRealizada: updates.containsKey('entrevistaRealizada')
              ? updates['entrevistaRealizada'] == 'true'
              : null,
          porGestionar: updates.containsKey('porGestionar')
              ? updates['porGestionar'] == 'true'
              : null,
        );
        // Persist updated list offline
        if (localCache != null) {
          await localCache!.save(_cached!);
        }
      }
    }

    // Invalidar el TTL para que el próximo fetch resincronice con el Sheet
    // (evita desfases si el servidor normalizó algún valor).
    _lastFetched = null;

    notifyListeners();
  }

  /// Crea una postulación nueva en la hoja.
  ///
  /// [draft] debe traer `rowIndex: 0`; el índice real lo devuelve el servidor.
  /// Si el servidor rellenó un hueco sin mover filas (`shifted == false`),
  /// insertamos localmente. Si insertó una fila y desplazó las existentes,
  /// ajustamos los índices cacheados y luego forzamos un refresh.
  Future<JobApplication> createApplication(JobApplication draft) async {
    if (_offline) {
      throw Exception(
        'Sin conexión a internet. No se puede crear en modo solo lectura.',
      );
    }

    final CreateResult result;
    try {
      result = await apiService.create(draft);
    } catch (e) {
      if (isNetworkError(e)) {
        _offline = true;
        notifyListeners();
      }
      throw Exception(friendlyErrorMessage(e));
    }

    final created = draft.copyWith(rowIndex: result.rowIndex);

    if (result.shifted) {
      // El servidor insertó una fila y desplazó las existentes. Ajustamos la
      // caché de inmediato para que los índices sigan siendo correctos aunque
      // el refresh falle, y luego intentamos resincronizar con el Sheet.
      _applyRowShift(result.rowIndex, created);
      if (localCache != null) {
        await localCache!.save(_cached!);
      }
      notifyListeners();

      _lastFetched = null;
      await fetchApplications(forceRefresh: true);
      return created;
    }

    // Se usó un hueco encima de la primera postulación: ningún rowIndex
    // existente cambia, así que basta con insertar la nueva en la caché.
    final current = _cached;
    _cached = [
      if (current != null)
        ...current.where((a) => a.rowIndex != created.rowIndex),
      created,
    ];

    if (localCache != null) {
      await localCache!.save(_cached!);
    }

    notifyListeners();
    return created;
  }

  /// Desplaza +1 los rowIndex >= [insertedRow] y agrega [created].
  ///
  /// Se usa como respaldo cuando el servidor confirma una inserción con
  /// desplazamiento; si el refresh posterior falla, la caché sigue apuntando
  /// a las filas correctas.
  void _applyRowShift(int insertedRow, JobApplication created) {
    final current = _cached;
    _cached = [
      if (current != null)
        for (final app in current)
          app.rowIndex >= insertedRow
              ? app.copyWith(rowIndex: app.rowIndex + 1)
              : app,
      created,
    ];
  }

  Future<void> _ensureCacheLoaded() async {
    if (_cacheLoaded || localCache == null) return;
    _cacheLoaded = true;
    if (_cached != null) return;
    final persisted = await localCache!.load();
    if (persisted != null && persisted.isNotEmpty) {
      _cached = persisted;
    }
  }

  Future<void> fetchApplications({bool forceRefresh = false}) async {
    await _ensureCacheLoaded();

    if (!forceRefresh && _cached != null && _lastFetched != null) {
      if (DateTime.now().difference(_lastFetched!) < _cacheTtl) return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final fresh = await apiService.fetchAll();
      _cached = fresh;
      _lastFetched = DateTime.now();
      _offline = false;
      _error = null;
      if (localCache != null) {
        await localCache!.save(fresh);
      }
    } catch (e) {
      final hasCache = _cached != null && _cached!.isNotEmpty;
      // Try to fall back to persisted cache if in-memory is still empty
      if (!hasCache && localCache != null) {
        final persisted = await localCache!.load();
        if (persisted != null && persisted.isNotEmpty) {
          _cached = persisted;
        }
      }

      final stillHasCache = _cached != null && _cached!.isNotEmpty;
      if (isNetworkError(e) && stillHasCache) {
        _offline = true;
        _error = null;
      } else {
        _offline = isNetworkError(e);
        _error = friendlyErrorMessage(e);
        // If network error and we have cache, keep offline=true but don't overwrite with error
        // so list screens show banner instead of full error. Only show full error when no data.
        if (isNetworkError(e) && stillHasCache) {
          _error = null;
        }
      }
    }

    _loading = false;
    notifyListeners();
  }
}
