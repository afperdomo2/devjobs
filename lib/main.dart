import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'providers/app_state.dart';
import 'screens/main_screen.dart';
import 'services/local_cache.dart';
import 'services/sheets_api_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await initializeDateFormatting('es');
  final prefs = await SharedPreferences.getInstance();
  final localCache = LocalCache(prefs);
  final apiService = SheetsApiService(baseUrl: kSheetsApiUrl);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(apiService: apiService, localCache: localCache),
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
      theme: AppTheme.light,
      home: const MainScreen(),
    );
  }
}
