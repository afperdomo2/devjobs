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

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  DashboardStats get dashboardStats {
    final apps = _cached;
    if (apps == null) {
      return const DashboardStats(total: 0, enRevision: 0, entrevistas: 0, ofertas: 0, rechazadas: 0);
    }
    final estados = apps.map((a) => (a.estado).trim().toLowerCase()).toList();
    return DashboardStats(
      total: apps.length,
      enRevision: estados.where((e) => e == 'en revisión').length,
      entrevistas: estados.where((e) => e == 'entrevista realizada').length,
      ofertas: estados.where((e) => e == 'oferta recibida' || e == 'ofertas recibidas').length,
      rechazadas: estados.where((e) => e == 'rechazada').length,
    );
  }

  List<JobApplication> getApplications(String filterMode) {
    var apps = _cached?.toList() ?? [];

    switch (filterMode) {
      case 'noRejected':
        apps = apps.where((a) => a.estado.trim().toLowerCase() != 'rechazada').toList();
      case 'onlyRejected':
        apps = apps.where((a) => a.estado.trim().toLowerCase() == 'rechazada').toList();
      case 'activas':
        apps = apps
            .where((a) => a.estado.trim().toLowerCase() != 'rechazada' && a.fechaSeguimiento.isNotEmpty)
            .toList();
      case 'pendientes':
        apps = apps
            .where((a) => a.estado.trim().toLowerCase() != 'rechazada' && a.fechaSeguimiento.isEmpty)
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

  Future<void> updateApplicationStatus(int rowIndex, String newStatus) async {
    await apiService.updateRow(rowIndex, {'estado': newStatus});
    await fetchApplications(forceRefresh: true);
  }
}
