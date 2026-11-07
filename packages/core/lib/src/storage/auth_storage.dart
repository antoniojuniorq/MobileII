import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o auth code da sessão.
abstract class AuthStorage {
  Future<String?> readAuthCode();
  Future<void> saveAuthCode(String code);
  Future<void> clear();
}

/// Implementação em memória (testes).
class InMemoryAuthStorage implements AuthStorage {
  InMemoryAuthStorage([this._code]);
  String? _code;

  @override
  Future<String?> readAuthCode() async => _code;

  @override
  Future<void> saveAuthCode(String code) async => _code = code;

  @override
  Future<void> clear() async => _code = null;
}

/// Implementação persistente (SharedPreferences).
class SharedPrefsAuthStorage implements AuthStorage {
  static const _key = 'ace.auth_code';

  @override
  Future<String?> readAuthCode() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> saveAuthCode(String code) async {
    await (await SharedPreferences.getInstance()).setString(_key, code);
  }

  @override
  Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}
