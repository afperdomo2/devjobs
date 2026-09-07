import 'dart:io';

import 'package:http/http.dart' as http;

bool isNetworkError(Object error) {
  if (error is SocketException) return true;
  if (error is http.ClientException) return true;
  // Unwrap if wrapped in generic Exception
  final msg = error.toString().toLowerCase();
  if (msg.contains('socketexception')) return true;
  if (msg.contains('failed host lookup')) return true;
  if (msg.contains('network is unreachable')) return true;
  if (msg.contains('connection failed')) return true;
  if (msg.contains('connection refused')) return true;
  return false;
}

String friendlyErrorMessage(Object error) {
  if (isNetworkError(error)) {
    return 'Sin conexión a internet. Verifica tu conexión e intenta de nuevo.';
  }
  // Strip "Exception: " prefix for cleaner display
  var msg = error.toString();
  if (msg.startsWith('Exception: ')) {
    msg = msg.substring('Exception: '.length);
  }
  // Truncate very long messages (e.g. HTML bodies)
  if (msg.length > 300) {
    msg = '${msg.substring(0, 300)}…';
  }
  return msg;
}
