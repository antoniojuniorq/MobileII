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

/// Um lote: posição na planta (em testadas de lote) e situação do dia.
class Lote {
  const Lote({
    required this.id,
    required this.numero,
    required this.x,
    required this.y,
    required this.w,
    required this.d,
    required this.status,
    this.visita,
  });

  final String id;
  final int numero;
  final double x;
  final double y;
  final double w;
  final double d;
  final LoteStatus status;
  final VisitaLote? visita;

  factory Lote.fromJson(Map<String, dynamic> json) => Lote(
        id: json['id'] as String,
        numero: (json['numero'] as num).toInt(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        w: (json['w'] as num).toDouble(),
        d: (json['d'] as num).toDouble(),
        status: LoteStatus.fromApi(json['status'] as String),
        visita: json['visita'] == null
            ? null
            : VisitaLote.fromJson(json['visita'] as Map<String, dynamic>),
      );
}

/// Fila dupla de lotes voltada para uma alameda.
class Conjunto {
  const Conjunto({
    required this.id,
    required this.nome,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.lotes,
  });

  final String id;
  final String nome;
  final double x;
  final double y;
  final double w;
  final double h;
  final List<Lote> lotes;

  int count(LoteStatus s) => lotes.where((l) => l.status == s).length;

  factory Conjunto.fromJson(Map<String, dynamic> json) => Conjunto(
        id: json['id'] as String,
        nome: json['nome'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        w: (json['w'] as num).toDouble(),
        h: (json['h'] as num).toDouble(),
        lotes: [
          for (final l in json['lotes'] as List)
            Lote.fromJson(l as Map<String, dynamic>),
        ],
      );
}

/// Área sem lotes residenciais (praça, escola, igreja).
class AreaLivre {
  const AreaLivre({
    required this.nome,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final String nome;
  final double x;
  final double y;
  final double w;
  final double h;

  factory AreaLivre.fromJson(Map<String, dynamic> json) => AreaLivre(
        nome: json['nome'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        w: (json['w'] as num).toDouble(),
        h: (json['h'] as num).toDouble(),
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
