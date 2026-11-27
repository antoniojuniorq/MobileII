import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

/// Aba "Perfil": dados da pessoa, quadra de atuação e saída da conta.
class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.agent,
    required this.onLogout,
    this.quadraNome,
    this.onChangeQuadra,
  });

  final Agent agent;
  final VoidCallback onLogout;
  final String? quadraNome;
  final VoidCallback? onChangeQuadra;

  @override
  Widget build(BuildContext context) {
    final muted =
        context.text.bodyMedium?.copyWith(color: context.ace.textMuted);
    final supervisor = agent.perfil == Perfil.supervisor;
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
                child: Icon(
                  supervisor ? Icons.insights_outlined : Icons.directions_walk,
                  size: 30,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AceSpacing.x3),
              Text(agent.nome, style: context.text.titleLarge),
              const SizedBox(height: AceSpacing.x1),
              Text(supervisor ? 'Supervisor' : 'Agente de campo', style: muted),
              Text('Matrícula ${agent.matricula}', style: muted),
              Text(agent.municipio, style: muted),
            ],
          ),
        ),
        if (quadraNome != null) ...[
          const SizedBox(height: AceSpacing.x3),
          AceCard(
            onTap: onChangeQuadra,
            child: Row(
              children: [
                Icon(Icons.grid_view_rounded, color: context.colors.primary),
                const SizedBox(width: AceSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quadra de atuação', style: muted),
                      Text(quadraNome!, style: context.text.titleMedium),
                    ],
                  ),
                ),
                if (onChangeQuadra != null) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
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
