enum VisitStatus {
  pendente('pendente'),
  visitado('visitado'),
  fechado('fechado'),
  recusado('recusado'),
  recuperado('recuperado'),
  comFoco('com_foco');

  const VisitStatus(this.apiValue);

  /// Valor usado na API.
  final String apiValue;

  static VisitStatus fromApi(String value) => VisitStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => VisitStatus.pendente,
      );
}

class Visit {
  const Visit({
    required this.id,
    required this.lote,
    required this.endereco,
    required this.quadra,
    required this.status,
    this.horario,
    this.observacao,
  });

  final int id;
  final String lote;
  final String endereco;
  final String quadra;
  final String? horario;
  final VisitStatus status;
  final String? observacao;

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
        id: (json['id'] as num).toInt(),
        lote: json['lote'] as String,
        endereco: json['endereco'] as String,
        quadra: json['quadra'] as String,
        horario: json['horario'] as String?,
        status: VisitStatus.fromApi(json['status'] as String),
        observacao: json['observacao'] as String?,
      );
}
