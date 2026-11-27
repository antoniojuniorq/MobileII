import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

/// Tradução entre a planta da quadra (Core) e o mapa 3D (Design System).
AceLotStatus aceLotStatusOf(LoteStatus s) => switch (s) {
      LoteStatus.pendente => AceLotStatus.pendente,
      LoteStatus.visitado => AceLotStatus.visitado,
      LoteStatus.semAcesso => AceLotStatus.semAcesso,
    };

List<Offset> _offsets(List<Ponto> pts) =>
    [for (final p in pts) Offset(p.x, p.y)];

List<AceIsoLot> isoLotsOf(Quadra q) => [
      for (final l in q.lotes)
        AceIsoLot(
          id: l.id,
          polygon: _offsets(l.poly),
          status: aceLotStatusOf(l.status),
          label: l.numero,
        ),
    ];

List<AceIsoGroup> isoGroupsOf(Quadra q) => [
      for (final c in q.conjuntos)
        AceIsoGroup(
          id: c.id,
          label: c.nome,
          bounds: Rect.fromLTRB(
              c.limites.minX, c.limites.minY, c.limites.maxX, c.limites.maxY),
        ),
    ];

List<AceIsoArea> isoAreasOf(Quadra q) => [
      for (final a in q.areas)
        AceIsoArea(
          label: a.nome,
          polygon: _offsets(a.poly),
          kind: a.praca ? AceIsoAreaKind.park : AceIsoAreaKind.building,
        ),
    ];

Map<AceLotStatus, int> lotCountsOf(Iterable<Lote> lotes) => {
      for (final s in AceLotStatus.values)
        s: lotes.where((l) => aceLotStatusOf(l.status) == s).length,
    };

/// "Lote 7 · QI 16 · Alameda 4"
String loteTitulo(Quadra q, Lote l) =>
    'Lote ${l.numero} · ${q.conjuntoDo(l).titulo}';

/// Lotes com visita registrada, a mais recente primeiro.
List<Lote> lotesTrabalhados(Quadra q) =>
    q.lotes.where((l) => l.visita != null).toList()
      ..sort((a, b) => b.visita!.horario.compareTo(a.visita!.horario));

/// "08:10 · 3 criadouros · 12 larvas" ou "08:31 · recusa ou ninguém em casa"
String visitaResumo(VisitaLote v) {
  if (v.resultado == ResultadoVisita.recusado) {
    return '${v.horario} · recusa ou ninguém em casa';
  }
  final a = v.achados;
  final partes = [
    if (a.criadouros > 0) _n(a.criadouros, 'criadouro', 'criadouros'),
    if (a.larvas > 0) _n(a.larvas, 'larva', 'larvas'),
    if (a.animais > 0) _n(a.animais, 'animal', 'animais'),
    if (a.focos > 0) _n(a.focos, 'foco', 'focos'),
  ];
  return [v.horario, if (partes.isEmpty) 'nada encontrado' else ...partes]
      .join(' · ');
}

String _n(int n, String um, String varios) => '$n ${n == 1 ? um : varios}';

/// Ícones das quatro contagens da visita.
abstract final class AchadoIcons {
  static const criadouros = Icons.water_drop_outlined;
  static const larvas = Icons.bug_report_outlined;
  static const animais = Icons.pets_outlined;
  static const focos = Icons.place_outlined;
}
