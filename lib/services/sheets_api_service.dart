import 'dart:convert';

import 'package:http/http.dart' as http;

import '../helpers/api_response.dart';
import '../models/job_application.dart';

class SheetsApiService {
  final String _baseUrl;
  final http.Client _client;

  SheetsApiService({required this._baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _jsonHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<JobApplication>> fetchAll() async {
    final uri = Uri.parse('$_baseUrl?action=all');
    final response = await _client.get(uri, headers: _jsonHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .map(
            (json) =>
                JobApplication.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    }
    throw Exception('Failed to load applications: ${response.statusCode}');
  }

  Future<DashboardStats> fetchDashboard() async {
    final uri = Uri.parse('$_baseUrl?action=dashboard');
    final response = await _client.get(uri, headers: _jsonHeaders);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return DashboardStats.fromJson(json);
    }
    throw Exception('Failed to load dashboard: ${response.statusCode}');
  }

  /// Envía un POST a la API de Apps Script. Apps Script ejecuta el script y
  /// responde 302 hacia la URL "echo" de script.googleusercontent.com (el
  /// resultado real vive ahí). Dart no sigue esa redirección para POST, así
  /// que la seguimos manualmente con un GET (patrón diseñado por Google).
  Future<http.Response> _postAction(Map<String, dynamic> payload) async {
    final request = http.Request('POST', Uri.parse(_baseUrl))
      ..headers.addAll(_jsonHeaders)
      ..body = jsonEncode(payload)
      ..followRedirects = false;

    var response = await http.Response.fromStream(await _client.send(request));

    if (response.statusCode == 302 || response.statusCode == 303) {
      final location = response.headers['location'];
      if (location != null) {
        response = await _client.get(
          Uri.parse(location),
          headers: const {'Accept': 'application/json'},
        );
      }
    }
    return response;
  }

  Future<void> updateRow(int rowIndex, Map<String, String> updates) async {
    final response = await _postAction({
      'action': 'update',
      'rowIndex': rowIndex,
      'updates': updates,
    });

    final error = postActionError('update', response.statusCode, response.body);
    if (error != null) {
      throw Exception(error);
    }
  }

  Future<int> create(JobApplication application) async {
    final response = await _postAction({
      'action': 'create',
      'data': application.toJson(),
    });

    final error = postActionError('create', response.statusCode, response.body);
    if (error != null) {
      throw Exception(error);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['rowIndex'] as int;
  }
}
