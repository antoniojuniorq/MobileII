/// Erro de chamada à API, já com mensagem pronta para mostrar ao usuário.
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Código estável da API (ex.: invalid_credentials, unauthorized, network).
  final String? code;

  /// Sessão inválida/expirada (diferente de credenciais erradas no login).
  bool get isUnauthorized => code == 'unauthorized';

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
