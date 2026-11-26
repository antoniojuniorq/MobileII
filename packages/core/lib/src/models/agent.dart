/// Como a pessoa entra no app: registra visitas ou acompanha a equipe.
enum Perfil {
  agente('agente'),
  supervisor('supervisor');

  const Perfil(this.apiValue);

  /// Valor usado na API.
  final String apiValue;

  static Perfil fromApi(String? value) =>
      value == 'supervisor' ? Perfil.supervisor : Perfil.agente;
}

class Agent {
  const Agent({
    required this.id,
    required this.nome,
    required this.matricula,
    required this.municipio,
    required this.area,
    this.perfil = Perfil.agente,
  });

  final int id;
  final String nome;
  final String matricula;
  final String municipio;
  final String area;
  final Perfil perfil;

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
        id: (json['id'] as num).toInt(),
        nome: json['nome'] as String,
        matricula: json['matricula'] as String,
        municipio: json['municipio'] as String,
        area: json['area'] as String,
        perfil: Perfil.fromApi(json['perfil'] as String?),
      );

  String get primeiroNome => nome.split(' ').first;
}
