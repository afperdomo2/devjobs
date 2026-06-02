import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config.dart';
import 'services/sheets_api_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  await dotenv.load();
  final apiService = SheetsApiService(baseUrl: kSheetsApiUrl);
  runApp(DevJobsApp(apiService: apiService));
}

class DevJobsApp extends StatelessWidget {
  final SheetsApiService apiService;

  const DevJobsApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevJobs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: DashboardScreen(apiService: apiService),
    );
  }
}
