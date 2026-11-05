import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lee una variable de entorno sin fallar si `dotenv` aún no se inicializó
/// (por ejemplo en tests de widgets que no cargan el `.env`).
String _env(String key) {
  try {
    return dotenv.env[key] ?? '';
  } catch (_) {
    return '';
  }
}

String get kSheetsApiUrl => _env('API_URL');

const String _defaultAiBaseUrl = 'https://opencode.ai/inference/go/openai/v1';
const String _defaultAiModel = 'deepseek-v4.1-flash';

/// Base URL del proveedor OpenAI-compatible.
///
/// Por defecto apunta a OpenCode Go. Para pay-as-you-go:
/// `https://opencode.ai/inference/openai/v1`.
String get kAiBaseUrl {
  final value = _env('AI_BASE_URL').trim();
  return value.isEmpty ? _defaultAiBaseUrl : value;
}

String get kAiApiKey => _env('AI_API_KEY').trim();

String get kAiModel {
  final value = _env('AI_MODEL').trim();
  return value.isEmpty ? _defaultAiModel : value;
}

/// La importación con IA solo existe si el build trae una API key.
bool get kAiEnabled => kAiApiKey.isNotEmpty;
