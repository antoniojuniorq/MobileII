class Agent {
  const Agent({
    required this.id,
    required this.nome,
    required this.matricula,
    required this.municipio,
    required this.area,
  });

  final int id;
  final String nome;
  final String matricula;
  final String municipio;
  final String area;

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
        id: (json['id'] as num).toInt(),
        nome: json['nome'] as String,
        matricula: json['matricula'] as String,
        municipio: json['municipio'] as String,
        area: json['area'] as String,
      );

  String get primeiroNome => nome.split(' ').first;
}
