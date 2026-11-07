import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../visit_presenters.dart';

/// Folha para registrar o resultado de uma visita.
class VisitStatusSheet extends StatefulWidget {
  const VisitStatusSheet({super.key, required this.visit, required this.onSave});

  final Visit visit;

  /// Retorna `null` se salvou, ou a mensagem de erro.
  final Future<String?> Function(VisitStatus status, String? observacao) onSave;

  @override
  State<VisitStatusSheet> createState() => _VisitStatusSheetState();
}

class _VisitStatusSheetState extends State<VisitStatusSheet> {
  late AceStatus _selected = aceStatusOf(widget.visit.status);
  late final TextEditingController _obs =
      TextEditingController(text: widget.visit.observacao);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(visitStatusOf(_selected), _obs.text.trim());
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AceSpacing.page,
        0,
        AceSpacing.page,
        AceSpacing.page + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lote ${v.lote}', style: context.text.titleLarge),
            Text(
              '${v.endereco} · ${v.quadra}',
              style: context.text.bodyMedium?.copyWith(color: context.ace.textMuted),
            ),
            const SizedBox(height: AceSpacing.x4),
            Text('Resultado da visita', style: context.text.titleSmall),
            const SizedBox(height: AceSpacing.x2),
            AceStatusSelector(
              value: _selected,
              onChanged: (s) => setState(() => _selected = s),
            ),
            const SizedBox(height: AceSpacing.x4),
            AceTextField(
              label: 'Observação',
              hint: 'Ex.: recipiente com água parada',
              controller: _obs,
              maxLines: 3,
              enabled: !_saving,
            ),
            if (_error != null) ...[
              const SizedBox(height: AceSpacing.x3),
              AceInlineMessage(message: _error!),
            ],
            const SizedBox(height: AceSpacing.x4),
            AceButton(
              label: 'Salvar visita',
              icon: Icons.check,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
