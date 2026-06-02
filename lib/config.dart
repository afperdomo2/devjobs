import 'package:flutter_dotenv/flutter_dotenv.dart';

String get kSheetsApiUrl => dotenv.env['API_URL'] ?? '';
