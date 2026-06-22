import 'package:flutter/foundation.dart';

import '../models/job_application.dart';
import '../services/sheets_api_service.dart';
import '../helpers/date_formatter.dart';

class AppState extends ChangeNotifier {
  final SheetsApiService apiService;

  List<JobApplication>? _cached;
  DateTime? _lastFetched;
  bool _loading = false;
  String? _error;
  int _currentTab = 0;

  static const _cacheTtl = Duration(minutes: 3);

  AppState({required this.apiService});

  int get currentTab => _currentTab;
  bool get loading => _loading;
  String? get error => _error;

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

  Future<void> fetchApplications({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null && _lastFetched != null) {
      if (DateTime.now().difference(_lastFetched!) < _cacheTtl) return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _cached = await apiService.fetchAll();
      _lastFetched = DateTime.now();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }
}
