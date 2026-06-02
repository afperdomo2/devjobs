import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'services/sheets_api_service.dart';
import 'providers/app_state.dart';
import 'screens/main_screen.dart';

void main() async {
  await dotenv.load();
  await initializeDateFormatting('es');
  final apiService = SheetsApiService(baseUrl: kSheetsApiUrl);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(apiService: apiService),
      child: const DevJobsApp(),
    ),
  );
}

class DevJobsApp extends StatelessWidget {
  const DevJobsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevJobs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const MainScreen(),
    );
  }
}
