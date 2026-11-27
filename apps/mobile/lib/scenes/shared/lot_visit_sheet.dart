import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import 'lot_presenters.dart';
import 'lot_visit_view_model.dart';

/// Folha aberta ao tocar num lote do mapa.
///
/// Agente: escolhe Visitado ou Recusado / não atendido; em Visitado preenche
/// criadouros, larvas, animais e locais com focos. Supervisor ([onSave] nulo):
/// só lê o que foi registrado.
class LotVisitSheet extends StatefulWidget {
  const LotVisitSheet({
    super.key,
    required this.quadra,
    required this.lote,
    this.onSave,
  });

  final Quadra quadra;
  final Lote lote;

  /// Retorna `null` se salvou, ou a mensagem de erro.
  final SalvarVisita? onSave;

  @override
  State<LotVisitSheet> createState() => _LotVisitSheetState();
}

class _LotVisitSheetState extends State<LotVisitSheet> {
  late final _vm = LotVisitViewModel(lote: widget.lote, salvar: widget.onSave);

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
  }

  /// Salvou: fecha a folha e avisa quem abriu.
  void _onChanged() {
    if (_vm.saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lote;
    final v = l.visita;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AceSpacing.page,
        0,
        AceSpacing.page,
        AceSpacing.page + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lote ${l.numero}',
                          style: context.text.headlineSmall),
                      Text(
                        '${widget.quadra.conjuntoDo(l).titulo} · ${widget.quadra.nome}',
                        style: context.text.bodyMedium
                            ?.copyWith(color: context.ace.textMuted),
                      ),
                    ],
                  ),
                ),
                AceLotBadge(status: aceLotStatusOf(l.status)),
              ],
            ),
            if (v != null) ...[
              const SizedBox(height: AceSpacing.x2),
              Text(
                'Registrado às ${v.horario} por ${v.agente}',
                style: context.text.bodySmall
                    ?.copyWith(color: context.ace.textMuted),
              ),
            ],
            const SizedBox(height: AceSpacing.x5),
            if (_vm.readOnly)
              _readOnlyBody(context)
            else
              ListenableBuilder(
                  listenable: _vm, builder: (context, _) => _editBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyBody(BuildContext context) {
    final v = widget.lote.visita;
    if (v == null) {
      return const AceInlineMessage(
        message: 'Lote ainda não visitado hoje.',
        type: AceFeedback.info,
      );
    }
    if (v.resultado == ResultadoVisita.recusado) {
      return const AceInlineMessage(
        message: 'Recusa ou ninguém em casa. Lote para recuperar.',
        type: AceFeedback.info,
      );
    }
    return _AchadosGrid(achados: v.achados);
  }

  Widget _editBody(BuildContext context) {
    final vm = _vm;
    final visitado = vm.visitado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Resultado da visita', style: context.text.titleMedium),
        const SizedBox(height: AceSpacing.x3),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AceChoiceCard(
                  compact: true,
                  icon: Icons.check_circle_outline,
                  title: 'Visitado',
                  subtitle: 'Casa inspecionada',
                  accent: AceLotStatus.visitado.color,
                  selected: visitado,
                  onTap: vm.saving
                      ? null
                      : () => vm.escolher(ResultadoVisita.visitado),
                ),
              ),
              const SizedBox(width: AceSpacing.x3),
              Expanded(
                child: AceChoiceCard(
                  compact: true,
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'Recusado / não atendido',
                  subtitle: 'Volta para recuperar',
                  accent: const Color(0xFF5F6A70),
                  selected: vm.resultado == ResultadoVisita.recusado,
                  onTap: vm.saving
                      ? null
                      : () => vm.escolher(ResultadoVisita.recusado),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: AceMotion.normal,
          curve: AceMotion.curve,
          alignment: Alignment.topCenter,
          child: !visitado
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AceSpacing.x5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('O que foi encontrado',
                          style: context.text.titleMedium),
                      const SizedBox(height: AceSpacing.x3),
                      AceCounterField(
                        label: 'Criadouros encontrados',
                        icon: AchadoIcons.criadouros,
                        value: vm.achados.criadouros,
                        enabled: !vm.saving,
                        onChanged: vm.setCriadouros,
                      ),
                      const SizedBox(height: AceSpacing.x2),
                      AceCounterField(
                        label: 'Larvas',
                        icon: AchadoIcons.larvas,
                        max: 9999,
                        value: vm.achados.larvas,
                        enabled: !vm.saving,
                        onChanged: vm.setLarvas,
                      ),
                      const SizedBox(height: AceSpacing.x2),
                      AceCounterField(
                        label: 'Animais',
                        icon: AchadoIcons.animais,
                        max: 99,
                        value: vm.achados.animais,
                        enabled: !vm.saving,
                        onChanged: vm.setAnimais,
                      ),
                      const SizedBox(height: AceSpacing.x2),
                      AceCounterField(
                        label: 'Locais com focos',
                        icon: AchadoIcons.focos,
                        value: vm.achados.focos,
                        enabled: !vm.saving,
                        onChanged: vm.setFocos,
                      ),
                    ],
                  ),
                ),
        ),
        if (vm.error != null) ...[
          const SizedBox(height: AceSpacing.x4),
          AceInlineMessage(message: vm.error!),
        ],
        const SizedBox(height: AceSpacing.x5),
        AceButton(
          label: 'Salvar visita',
          icon: Icons.check,
          loading: vm.saving,
          onPressed: vm.salvar,
        ),
      ],
    );
  }
}

/// Os quatro números da visita, em 2 × 2.
class _AchadosGrid extends StatelessWidget {
  const _AchadosGrid({required this.achados});
  final Achados achados;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Criadouros', achados.criadouros, AchadoIcons.criadouros),
      ('Larvas', achados.larvas, AchadoIcons.larvas),
      ('Animais', achados.animais, AchadoIcons.animais),
      ('Locais com focos', achados.focos, AchadoIcons.focos),
    ];
    return Column(
      children: [
        for (var r = 0; r < 2; r++) ...[
          if (r == 1) const SizedBox(height: AceSpacing.x3),
          Row(
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i == 1) const SizedBox(width: AceSpacing.x3),
                Expanded(
                  child: AceStatCard(
                    value: '${items[r * 2 + i].$2}',
                    label: items[r * 2 + i].$1,
                    icon: items[r * 2 + i].$3,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
