import 'package:flutter/foundation.dart';

import '../helpers/date_formatter.dart';
import '../helpers/network_error.dart';
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
  int _currentTab = 0;
  bool _cacheLoaded = false;

  static const _cacheTtl = Duration(minutes: 3);

  AppState({required this.apiService, this.localCache});

  int get currentTab => _currentTab;
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

  DashboardStats get dashboardStats {
    final apps = _cached;
    if (apps == null) {
      return const DashboardStats(total: 0, activas: 0, entrevistas: 0, rechazadas: 0);
    }
    final estados = apps.map((a) => (a.estado).trim().toLowerCase()).toList();
    return DashboardStats(
      total: apps.length,
      activas: estados.where((e) => e != 'enviada' && e != 'rechazada' && e != 'retirada').length,
      entrevistas: apps.where((a) => a.entrevistaRealizada).length,
      rechazadas: estados.where((e) => e == 'rechazada' || e == 'retirada').length,
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
            default:
              return false;
          }
        })
        .toList();
    apps.sort(_sortByDate);
    return apps;
  }

  List<JobApplication> getApplications(String filterMode) {
    var apps = _cached?.toList() ?? [];

    switch (filterMode) {
      case 'noRejected':
        apps = apps.where((a) => !_isTerminal(a.estado)).toList();
      case 'onlyRejected':
        apps = apps.where((a) => _isTerminal(a.estado)).toList();
      case 'activas':
        apps = apps
            .where((a) {
              final e = a.estado.trim().toLowerCase();
              return e != 'enviada' && e != 'rechazada' && e != 'retirada';
            })
            .toList();
      case 'enviadas':
        apps = apps
            .where((a) => a.estado.trim().toLowerCase() == 'enviada')
            .toList();
    }

    apps.sort(_sortByDate);
    return apps;
  }

  int _sortByDate(JobApplication a, JobApplication b) {
    final aHasSeg = a.fechaSeguimiento.isNotEmpty;
    final bHasSeg = b.fechaSeguimiento.isNotEmpty;

    if (aHasSeg && !bHasSeg) return -1;
    if (!aHasSeg && bHasSeg) return 1;

    if (aHasSeg && bHasSeg) {
      final c = _compareDateStrings(b.fechaSeguimiento, a.fechaSeguimiento);
      if (c != 0) return c;
    }

    return _compareDateStrings(b.fechaPostulacion, a.fechaPostulacion);
  }

  bool _isTerminal(String estado) {
    final e = estado.trim().toLowerCase();
    return e == 'rechazada' || e == 'retirada';
  }

  int _compareDateStrings(String a, String b) {
    final dA = parseDate(a);
    final dB = parseDate(b);
    if (dA == null && dB == null) return 0;
    if (dA == null) return 1;
    if (dB == null) return -1;
    return dA.compareTo(dB);
  }

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
          contacto: updates['contacto'],
          comentarios: updates['comentarios'],
          entrevistaRealizada: updates.containsKey('entrevistaRealizada')
              ? updates['entrevistaRealizada'] == 'true'
              : null,
        );
        // Persist updated list offline
        if (localCache != null) {
          await localCache!.save(_cached!);
        }
      }
    }

    notifyListeners();
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
