import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import 'lot_presenters.dart';

/// Progresso da quadra: barra + três contagens por situação.
class QuadraProgressCard extends StatelessWidget {
  const QuadraProgressCard({super.key, required this.quadra, this.onChange});

  final Quadra quadra;

  /// Mostra "Trocar" ao lado do nome (agente).
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final r = quadra.resumo;
    final feitos = r.visitados + r.semAcesso;
    return AceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nome, style: context.text.titleLarge),
                    Text(r.bairro,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.ace.textMuted)),
                  ],
                ),
              ),
              if (onChange != null)
                TextButton(onPressed: onChange, child: const Text('Trocar')),
            ],
          ),
          const SizedBox(height: AceSpacing.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$feitos', style: context.text.displaySmall),
              const SizedBox(width: AceSpacing.x2),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'de ${r.totalLotes} lotes trabalhados',
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.ace.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AceSpacing.x3),
          AceProgressBar(
              value: r.progresso, semanticLabel: 'Lotes trabalhados'),
          const SizedBox(height: AceSpacing.x4),
          AceLotLegend(counts: lotCountsOf(quadra.lotes)),
        ],
      ),
    );
  }
}

/// Soma do que foi encontrado nos lotes visitados (grade 2 × 2).
class AchadosRow extends StatelessWidget {
  const AchadosRow({super.key, required this.achados});
  final Achados achados;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Criadouros', achados.criadouros, AchadoIcons.criadouros),
      ('Larvas', achados.larvas, AchadoIcons.larvas),
      ('Animais', achados.animais, AchadoIcons.animais),
      ('Locais com focos', achados.focos, AchadoIcons.focos),
    ];
    Widget tile((String, int, IconData) it) => Semantics(
          label: '${it.$1}: ${it.$2}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(AceSpacing.x3),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AceRadius.md),
              border: Border.all(color: context.ace.line),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AceSpacing.x2),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AceRadius.sm),
                  ),
                  child: Icon(it.$3,
                      size: 20, color: context.colors.onPrimaryContainer),
                ),
                const SizedBox(width: AceSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${it.$2}', style: context.text.titleLarge),
                      Text(
                        it.$1,
                        maxLines: 2,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.ace.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return Column(
      children: [
        for (var r = 0; r < 2; r++) ...[
          if (r == 1) const SizedBox(height: AceSpacing.x2),
          Row(
            children: [
              Expanded(child: tile(items[r * 2])),
              const SizedBox(width: AceSpacing.x2),
              Expanded(child: tile(items[r * 2 + 1])),
            ],
          ),
        ],
      ],
    );
  }
}

/// Linha de um lote trabalhado: número na cor da situação, alameda e resumo.
class LoteTile extends StatelessWidget {
  const LoteTile(
      {super.key, required this.quadra, required this.lote, this.onTap});

  final Quadra quadra;
  final Lote lote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = aceLotStatusOf(lote.status);
    final v = lote.visita;
    return AceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AceSpacing.x3),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: s.color,
                borderRadius: BorderRadius.circular(AceRadius.md)),
            child: Text(
              lote.numero,
              style: context.text.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AceSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quadra.conjuntoDo(lote).titulo,
                    style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  v == null ? 'A visitar' : visitaResumo(v),
                  style: context.text.bodySmall
                      ?.copyWith(color: context.ace.textMuted),
                ),
              ],
            ),
          ),
          Icon(s.icon, color: s.colors(Theme.of(context).brightness).fg),
        ],
      ),
    );
  }
}
