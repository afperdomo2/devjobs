import 'dart:convert';

import 'package:http/http.dart' as http;

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
          .map((json) => JobApplication.fromJson(Map<String, dynamic>.from(json as Map)))
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

  Future<void> updateRow(int rowIndex, Map<String, String> updates) async {
    final uri = Uri.parse(_baseUrl);
    final body = jsonEncode({
      'action': 'update',
      'rowIndex': rowIndex,
      'updates': updates,
    });

    final request = http.Request('POST', uri)
      ..headers.addAll(_jsonHeaders)
      ..body = body
      ..followRedirects = true;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Failed to update: ${response.statusCode}\n${response.body}');
    }
  }

  Future<int> create(JobApplication application) async {
    final uri = Uri.parse(_baseUrl);
    final body = jsonEncode({
      'action': 'create',
      'data': application.toJson(),
    });

    final request = http.Request('POST', uri)
      ..headers.addAll(_jsonHeaders)
      ..body = body
      ..followRedirects = true;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['rowIndex'] as int;
    }
    throw Exception('Failed to create: ${response.statusCode}');
  }
}
