import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';

/// Campo de texto com rótulo sempre visível acima (não some ao digitar).
///
/// Com [obscure] vira campo de senha: teclado de texto próprio para senha,
/// sem sugestões nem correção (alguns teclados Android travam a digitação em
/// campos ocultos com sugestões ligadas) e um botão para mostrar a senha.
class AceTextField extends StatefulWidget {
  const AceTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? error;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  @override
  State<AceTextField> createState() => _AceTextFieldState();
}

class _AceTextFieldState extends State<AceTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final secret = w.obscure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(w.label, style: context.text.titleSmall),
        const SizedBox(height: AceSpacing.x2),
        TextField(
          controller: w.controller,
          focusNode: w.focusNode,
          obscureText: secret && _hidden,
          keyboardType: secret ? TextInputType.visiblePassword : w.keyboardType,
          autocorrect: !secret,
          enableSuggestions: !secret,
          autofillHints: w.autofillHints,
          onChanged: w.onChanged,
          maxLines: secret ? 1 : w.maxLines,
          enabled: w.enabled,
          textInputAction: w.textInputAction,
          onSubmitted: w.onSubmitted,
          style: context.text.bodyLarge,
          decoration: InputDecoration(
            hintText: w.hint,
            helperText: w.helper,
            errorText: w.error,
            prefixIcon: w.icon == null ? null : Icon(w.icon),
            suffixIcon: !secret
                ? null
                : IconButton(
                    tooltip: _hidden ? 'Mostrar senha' : 'Esconder senha',
                    icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  ),
          ),
        ),
      ],
    );
  }
}
