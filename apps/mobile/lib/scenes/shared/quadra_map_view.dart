import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import 'lot_presenters.dart';

/// Mapa 3D da quadra com legenda e atalhos por alameda.
///
/// Afastado: tocar num conjunto aproxima. Aproximado: tocar num lote chama
/// [onLoteTap]. Usado pelo agente (registra) e pelo supervisor (consulta).
class QuadraMapView extends StatefulWidget {
  const QuadraMapView({
    super.key,
    required this.quadra,
    required this.onLoteTap,
    this.selectedLoteId,
    this.hint =
        'Toque num conjunto para aproximar e num lote para registrar a visita.',
  });

  final Quadra quadra;
  final ValueChanged<Lote> onLoteTap;
  final String? selectedLoteId;
  final String hint;

  @override
  State<QuadraMapView> createState() => _QuadraMapViewState();
}

class _QuadraMapViewState extends State<QuadraMapView> {
  final _map = AceIsoMapController();
  AceIsoGroup? _focused;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quadra;
    // atalhos: QI 01…47 primeiro, depois QC e a faixa comercial
    int rank(String nome) => nome.startsWith('QI')
        ? 0
        : nome.startsWith('QC')
            ? 1
            : 2;
    final conjuntos = [...q.conjuntos]..sort((a, b) =>
        rank(a.nome) != rank(b.nome)
            ? rank(a.nome) - rank(b.nome)
            : a.nome.compareTo(b.nome));
    final order = {
      for (var i = 0; i < conjuntos.length; i++) conjuntos[i].id: i
    };
    final groups = isoGroupsOf(q)
      ..sort((a, b) => order[a.id]!.compareTo(order[b.id]!));
    final focusedConjunto = _focused == null
        ? null
        : q.conjuntos.where((c) => c.id == _focused!.id).firstOrNull;
    final lotsForLegend = focusedConjunto?.lotes ?? q.lotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AceSpacing.page, AceSpacing.x3, AceSpacing.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      focusedConjunto?.titulo ??
                          '${q.nome} · ${q.resumo.totalLotes} lotes',
                      style: context.text.titleMedium,
                    ),
                  ),
                  if (_focused != null)
                    TextButton.icon(
                      onPressed: _map.showAll,
                      icon: const Icon(Icons.zoom_out_map, size: 20),
                      label: const Text('Quadra inteira'),
                    ),
                ],
              ),
              const SizedBox(height: AceSpacing.x2),
              AceLotLegend(counts: lotCountsOf(lotsForLegend)),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: AceIsoMap(
                  controller: _map,
                  lots: isoLotsOf(q),
                  groups: groups,
                  areas: isoAreasOf(q),
                  worldWidth: q.largura,
                  worldHeight: q.altura,
                  selectedLotId: widget.selectedLoteId,
                  onGroupFocused: (g) => setState(() => _focused = g),
                  onLotTap: (iso) => widget
                      .onLoteTap(q.lotes.firstWhere((l) => l.id == iso.id)),
                  semanticLabel: 'Mapa 3D da ${q.nome}',
                ),
              ),
              if (_focused == null)
                Positioned(
                  left: AceSpacing.page,
                  right: AceSpacing.page,
                  bottom: AceSpacing.x2,
                  child: IgnorePointer(
                    child: Text(
                      widget.hint,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall
                          ?.copyWith(color: context.ace.textMuted),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: AceSpacing.touch + AceSpacing.x4,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AceSpacing.page, vertical: AceSpacing.x2),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: AceSpacing.x2),
            itemBuilder: (context, i) {
              final g = groups[i];
              final c = conjuntos[i];
              final pend = c.count(LoteStatus.pendente);
              return ChoiceChip(
                selected: _focused?.id == g.id,
                showCheckmark: false,
                avatar: pend == 0
                    ? Icon(Icons.check_circle,
                        size: 18, color: AceLotStatus.visitado.color)
                    : null,
                label: Text(g.label),
                onSelected: (_) => _map.focusGroup(g.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
