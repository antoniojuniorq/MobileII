import '../models/quadra.dart';
import '../network/api_client.dart';
import '../storage/auth_storage.dart';

/// Quadras de atuação, planta dos lotes e registro de visita por lote.
class QuadrasRepository {
  QuadrasRepository(this._api, this._storage);

  final ApiClient _api;
  final AuthStorage _storage;

  Future<List<QuadraResumo>> list() async => [
        for (final q in await _api.get('/quadras') as List)
          QuadraResumo.fromJson(q as Map<String, dynamic>),
      ];

  Future<Quadra> get(String id) async => Quadra.fromJson(
        await _api.get('/quadras/$id') as Map<String, dynamic>,
      );

  /// Registra o resultado da visita. Em recusa os números são ignorados.
  Future<Lote> registrarVisita({
    required String quadraId,
    required String loteId,
    required ResultadoVisita resultado,
    Achados achados = const Achados(),
  }) async {
    final json = await _api.post(
      '/quadras/$quadraId/lotes/$loteId/visita',
      body: {
        'resultado': resultado.apiValue,
        if (resultado == ResultadoVisita.visitado) ...achados.toJson(),
      },
    );
    return Lote.fromJson(json as Map<String, dynamic>);
  }

  /// Quadra escolhida pelo agente (fica salva entre sessões).
  Future<String?> quadraEscolhida() => _storage.readQuadra();

  Future<void> escolherQuadra(String id) => _storage.saveQuadra(id);
}
