import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a sessão (auth code e perfil) e a quadra escolhida pelo agente.
abstract class AuthStorage {
  Future<String?> readAuthCode();
  Future<void> saveAuthCode(String code);

  /// Perfil da sessão (`agente` ou `supervisor`).
  Future<String?> readPerfil();
  Future<void> savePerfil(String perfil);

  /// Quadra de atuação. Não é apagada no logout.
  Future<String?> readQuadra();
  Future<void> saveQuadra(String id);

  /// Encerra a sessão (auth code e perfil).
  Future<void> clear();
}

/// Implementação em memória (testes).
class InMemoryAuthStorage implements AuthStorage {
  InMemoryAuthStorage([this._code, this._perfil, this._quadra]);
  String? _code;
  String? _perfil;
  String? _quadra;

  @override
  Future<String?> readAuthCode() async => _code;

  @override
  Future<void> saveAuthCode(String code) async => _code = code;

  @override
  Future<String?> readPerfil() async => _perfil;

  @override
  Future<void> savePerfil(String perfil) async => _perfil = perfil;

  @override
  Future<String?> readQuadra() async => _quadra;

  @override
  Future<void> saveQuadra(String id) async => _quadra = id;

  @override
  Future<void> clear() async {
    _code = null;
    _perfil = null;
  }
}

/// Implementação persistente (SharedPreferences).
class SharedPrefsAuthStorage implements AuthStorage {
  static const _key = 'ace.auth_code';
  static const _perfilKey = 'ace.perfil';
  static const _quadraKey = 'ace.quadra';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> readAuthCode() async => (await _prefs).getString(_key);

  @override
  Future<void> saveAuthCode(String code) async =>
      (await _prefs).setString(_key, code);

  @override
  Future<String?> readPerfil() async => (await _prefs).getString(_perfilKey);

  @override
  Future<void> savePerfil(String perfil) async =>
      (await _prefs).setString(_perfilKey, perfil);

  @override
  Future<String?> readQuadra() async => (await _prefs).getString(_quadraKey);

  @override
  Future<void> saveQuadra(String id) async =>
      (await _prefs).setString(_quadraKey, id);

  @override
  Future<void> clear() async {
    final p = await _prefs;
    await p.remove(_key);
    await p.remove(_perfilKey);
  }
}
