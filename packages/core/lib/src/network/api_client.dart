import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

typedef AuthCodeProvider = Future<String?> Function();

/// Cliente HTTP JSON. Injeta o `Authorization: Bearer <auth_code>` quando há
/// sessão e converte falhas em [ApiException].
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.authCodeProvider,
    this.timeout = const Duration(seconds: 10),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final AuthCodeProvider? authCodeProvider;
  final Duration timeout;
  final http.Client _http;

  Future<Object?> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Object?> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Object?> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  void close() => _http.close();

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final code = await authCodeProvider?.call();
    if (code != null && code.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $code';
    }

    try {
      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      return _handle(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'O servidor demorou para responder. Tente de novo.',
        code: 'timeout',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Sem conexão com o servidor. Verifique a internet e a rede.',
        code: 'network',
      );
    }
  }

  Object? _handle(http.Response response) {
    Object? json;
    try {
      final text = utf8.decode(response.bodyBytes);
      json = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      json = null;
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok) return json;

    var message = 'Algo deu errado. Tente novamente.';
    String? code;
    if (json is Map && json['error'] is Map) {
      final error = json['error'] as Map;
      message = (error['message'] as String?) ?? message;
      code = error['code'] as String?;
    }
    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      code: code,
    );
  }
}
