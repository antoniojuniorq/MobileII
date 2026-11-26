import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';

/// Campo de contagem: botões − e + grandes (uso com luva) e número digitável.
class AceCounterField extends StatefulWidget {
  const AceCounterField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.max = 999,
    this.enabled = true,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final IconData? icon;
  final int max;
  final bool enabled;

  @override
  State<AceCounterField> createState() => _AceCounterFieldState();
}

class _AceCounterFieldState extends State<AceCounterField> {
  late final _ctrl = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void didUpdateWidget(AceCounterField old) {
    super.didUpdateWidget(old);
    if (int.tryParse(_ctrl.text) != widget.value) {
      _ctrl.text = '${widget.value}';
    }
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _ctrl.text.isEmpty) _ctrl.text = '${widget.value}';
      if (_focus.hasFocus) {
        _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _set(int v) => widget.onChanged(v.clamp(0, widget.max));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: '${widget.label}: ${widget.value}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(AceSpacing.x3, AceSpacing.x2, AceSpacing.x2, AceSpacing.x2),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AceRadius.md),
          border: Border.all(color: widget.value > 0 ? c.primary : context.ace.line, width: widget.value > 0 ? 1.5 : 1),
        ),
        child: Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 22, color: widget.value > 0 ? c.primary : context.ace.textMuted),
              const SizedBox(width: AceSpacing.x3),
            ],
            Expanded(
              child: Text(widget.label, style: context.text.titleSmall),
            ),
            _StepButton(
              icon: Icons.remove,
              tooltip: 'Diminuir ${widget.label.toLowerCase()}',
              onPressed: widget.enabled && widget.value > 0 ? () => _set(widget.value - 1) : null,
            ),
            SizedBox(
              width: 56,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                enabled: widget.enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                style: context.text.headlineSmall,
                decoration: const InputDecoration(
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: AceSpacing.x2),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (t) {
                  final v = int.tryParse(t);
                  if (v != null) _set(v);
                },
              ),
            ),
            _StepButton(
              icon: Icons.add,
              tooltip: 'Aumentar ${widget.label.toLowerCase()}',
              filled: true,
              onPressed: widget.enabled && widget.value < widget.max ? () => _set(widget.value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed, this.filled = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = IconButton.styleFrom(
      minimumSize: const Size(AceSpacing.touch, AceSpacing.touch),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AceRadius.md)),
      backgroundColor: filled ? c.primaryContainer : Colors.transparent,
      foregroundColor: filled ? c.onPrimaryContainer : c.onSurface,
    );
    return IconButton(onPressed: onPressed, icon: Icon(icon), tooltip: tooltip, style: style);
  }
}
