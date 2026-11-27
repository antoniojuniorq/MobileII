/// Situação de um lote no dia.
enum LoteStatus {
  pendente('pendente'),
  visitado('visitado'),

  /// Recusa ou ninguém em casa.
  semAcesso('sem_acesso');

  const LoteStatus(this.apiValue);
  final String apiValue;

  static LoteStatus fromApi(String value) => LoteStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => LoteStatus.pendente,
      );
}

/// Resultado escolhido pelo agente ao tocar no lote.
enum ResultadoVisita {
  visitado('visitado'),

  /// Recusado ou não atendido.
  recusado('recusado');

  const ResultadoVisita(this.apiValue);
  final String apiValue;

  static ResultadoVisita fromApi(String value) =>
      value == 'recusado' ? ResultadoVisita.recusado : ResultadoVisita.visitado;
}

/// O que foi encontrado no lote visitado.
class Achados {
  const Achados({
    this.criadouros = 0,
    this.larvas = 0,
    this.animais = 0,
    this.focos = 0,
  });

  final int criadouros;
  final int larvas;
  final int animais;
  final int focos;

  Achados operator +(Achados o) => Achados(
        criadouros: criadouros + o.criadouros,
        larvas: larvas + o.larvas,
        animais: animais + o.animais,
        focos: focos + o.focos,
      );

  Map<String, int> toJson() => {
        'criadouros': criadouros,
        'larvas': larvas,
        'animais': animais,
        'focos': focos,
      };
}

class VisitaLote {
  const VisitaLote({
    required this.resultado,
    required this.horario,
    required this.agente,
    this.achados = const Achados(),
  });

  final ResultadoVisita resultado;
  final String horario;
  final String agente;
  final Achados achados;

  factory VisitaLote.fromJson(Map<String, dynamic> json) => VisitaLote(
        resultado: ResultadoVisita.fromApi(json['resultado'] as String),
        horario: json['horario'] as String,
        agente: json['agente'] as String,
        achados: Achados(
          criadouros: (json['criadouros'] as num? ?? 0).toInt(),
          larvas: (json['larvas'] as num? ?? 0).toInt(),
          animais: (json['animais'] as num? ?? 0).toInt(),
          focos: (json['focos'] as num? ?? 0).toInt(),
        ),
      );
}

/// Ponto da planta (x para leste, y para sul; unidade do PDF, ~1 m).
typedef Ponto = ({double x, double y});

List<Ponto> _poly(Object? json) => [
      for (final p in json as List)
        (x: ((p as List)[0] as num).toDouble(), y: (p[1] as num).toDouble()),
    ];

/// Retângulo que envolve um contorno.
({double minX, double minY, double maxX, double maxY}) limitesDe(Iterable<Ponto> pts) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final p in pts) {
    if (p.x < minX) minX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.x > maxX) maxX = p.x;
    if (p.y > maxY) maxY = p.y;
  }
  return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
}

/// Um lote: contorno na planta da Prefeitura e situação do dia.
class Lote {
  const Lote({
    required this.id,
    required this.numero,
    required this.poly,
    required this.status,
    this.visita,
  });

  final String id;

  /// Como está na planta: "7", "15-A".
  final String numero;
  final List<Ponto> poly;
  final LoteStatus status;
  final VisitaLote? visita;

  factory Lote.fromJson(Map<String, dynamic> json) => Lote(
        id: json['id'] as String,
        numero: json['numero'].toString(),
        poly: _poly(json['poly']),
        status: LoteStatus.fromApi(json['status'] as String),
        visita: json['visita'] == null
            ? null
            : VisitaLote.fromJson(json['visita'] as Map<String, dynamic>),
      );
}

/// Quadra interna (QI), quadra comercial (QC) ou faixa comercial: grupo de
/// lotes com numeração própria.
class Conjunto {
  const Conjunto({
    required this.id,
    required this.nome,
    required this.lotes,
    this.alameda,
  });

  final String id;

  /// "QI 16"
  final String nome;

  /// Alameda de acesso, quando houver ("Alameda 4").
  final String? alameda;
  final List<Lote> lotes;

  int count(LoteStatus s) => lotes.where((l) => l.status == s).length;

  /// "QI 16 · Alameda 4"
  String get titulo => alameda == null ? nome : '$nome · $alameda';

  ({double minX, double minY, double maxX, double maxY}) get limites =>
      limitesDe(lotes.expand((l) => l.poly));

  factory Conjunto.fromJson(Map<String, dynamic> json) => Conjunto(
        id: json['id'] as String,
        nome: json['nome'] as String,
        alameda: json['alameda'] as String?,
        lotes: [
          for (final l in json['lotes'] as List)
            Lote.fromJson(l as Map<String, dynamic>),
        ],
      );
}

/// Área sem lotes: praça, escola, igreja, postos.
class AreaLivre {
  const AreaLivre({required this.nome, required this.poly, this.praca = false});

  final String nome;
  final List<Ponto> poly;

  /// Área verde (praça, lazer); senão é um equipamento público.
  final bool praca;

  factory AreaLivre.fromJson(Map<String, dynamic> json) => AreaLivre(
        nome: json['nome'] as String,
        poly: _poly(json['poly']),
        praca: json['tipo'] == 'park',
      );
}

/// Quadra na lista de escolha (sem a planta).
class QuadraResumo {
  const QuadraResumo({
    required this.id,
    required this.nome,
    required this.bairro,
    required this.totalLotes,
    required this.visitados,
    required this.semAcesso,
    required this.pendentes,
  });

  final String id;
  final String nome;
  final String bairro;
  final int totalLotes;
  final int visitados;
  final int semAcesso;
  final int pendentes;

  /// Lotes com resultado (visitados ou sem acesso) / total.
  double get progresso =>
      totalLotes == 0 ? 0 : (visitados + semAcesso) / totalLotes;

  factory QuadraResumo.fromJson(Map<String, dynamic> json) => QuadraResumo(
        id: json['id'] as String,
        nome: json['nome'] as String,
        bairro: json['bairro'] as String,
        totalLotes: (json['total_lotes'] as num).toInt(),
        visitados: (json['visitados'] as num).toInt(),
        semAcesso: (json['sem_acesso'] as num).toInt(),
        pendentes: (json['pendentes'] as num).toInt(),
      );
}

/// Quadra com a planta completa.
class Quadra {
  const Quadra({
    required this.resumo,
    required this.largura,
    required this.altura,
    required this.areas,
    required this.conjuntos,
  });

  final QuadraResumo resumo;
  final double largura;
  final double altura;
  final List<AreaLivre> areas;
  final List<Conjunto> conjuntos;

  String get id => resumo.id;
  String get nome => resumo.nome;

  Iterable<Lote> get lotes => conjuntos.expand((c) => c.lotes);

  /// Soma do que foi encontrado em todos os lotes visitados.
  Achados get achados => lotes
      .map((l) => l.visita?.achados ?? const Achados())
      .fold(const Achados(), (a, b) => a + b);

  Conjunto conjuntoDo(Lote lote) =>
      conjuntos.firstWhere((c) => c.lotes.any((l) => l.id == lote.id));

  factory Quadra.fromJson(Map<String, dynamic> json) => Quadra(
        resumo: QuadraResumo.fromJson(json),
        largura: (json['largura'] as num).toDouble(),
        altura: (json['altura'] as num).toDouble(),
        areas: [
          for (final a in json['areas'] as List)
            AreaLivre.fromJson(a as Map<String, dynamic>),
        ],
        conjuntos: [
          for (final c in json['conjuntos'] as List)
            Conjunto.fromJson(c as Map<String, dynamic>),
        ],
      );
}
