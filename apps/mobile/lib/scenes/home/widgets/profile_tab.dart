import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../home_view_model.dart';

/// Aba "Perfil": dados do agente e saída da conta.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.vm, required this.onLogout});

  final HomeViewModel vm;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final agent = vm.agent;
    if (agent == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final muted = context.text.bodyMedium?.copyWith(color: context.ace.textMuted);
    return ListView(
      padding: const EdgeInsets.all(AceSpacing.page),
      children: [
        AceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: context.colors.primaryContainer,
                child: Icon(Icons.person_outline,
                    size: 30, color: context.colors.onPrimaryContainer),
              ),
              const SizedBox(height: AceSpacing.x3),
              Text(agent.nome, style: context.text.titleLarge),
              const SizedBox(height: AceSpacing.x1),
              Text('Matrícula ${agent.matricula}', style: muted),
              Text(agent.area, style: muted),
              Text(agent.municipio, style: muted),
            ],
          ),
        ),
        const SizedBox(height: AceSpacing.x5),
        AceButton(
          label: 'Sair da conta',
          icon: Icons.logout,
          variant: AceButtonVariant.secondary,
          onPressed: onLogout,
        ),
      ],
    );
  }
}
