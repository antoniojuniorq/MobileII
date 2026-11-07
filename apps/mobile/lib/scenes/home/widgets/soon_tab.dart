import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

/// Aba ainda não implementada (protótipo): diz o que virá.
class SoonTab extends StatelessWidget {
  const SoonTab({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: AceEmptyState(icon: icon, title: title, message: message),
      ),
    );
  }
}
