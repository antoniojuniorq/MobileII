import '../models/summary.dart';
import '../models/visit.dart';
import '../network/api_client.dart';

class VisitsRepository {
  VisitsRepository(this._api);
  final ApiClient _api;

  Future<Summary> summaryToday() async => Summary.fromJson(
        await _api.get('/summary/today') as Map<String, dynamic>,
      );

  Future<List<Visit>> list({VisitStatus? status}) async {
    final json = await _api.get(
      '/visits',
      query: status == null ? null : {'status': status.apiValue},
    );
    return (json as List)
        .map((e) => Visit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Visit> update(
    int id, {
    required VisitStatus status,
    String? observacao,
  }) async {
    final json = await _api.patch(
      '/visits/$id',
      body: {
        'status': status.apiValue,
        if (observacao != null && observacao.isNotEmpty)
          'observacao': observacao,
      },
    );
    return Visit.fromJson(json as Map<String, dynamic>);
  }
}
