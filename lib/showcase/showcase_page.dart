import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

/// Galeria viva do Design System: cada seção mostra um grupo de tokens ou componentes.
class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key, required this.isDark, required this.onToggleTheme});
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  AceStatus? _status = AceStatus.visitado;
  bool _loading = false;
  int _nav = 0;
  String _profile = 'agente';

  Future<void> _fakeSave() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    AceSnackbar.show(context, 'Visita registrada', type: AceFeedback.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACE CONTROL'),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Usar tema claro' : 'Usar tema escuro',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AceSpacing.page, 0, AceSpacing.page, AceSpacing.x8),
        children: [
          const SizedBox(height: AceSpacing.x5),
          Text('Design System', style: context.text.displaySmall),
          const SizedBox(height: AceSpacing.x2),
          Text(
            'Tokens e componentes para o trabalho de campo dos agentes de combate a endemias.',
            style: context.text.bodyLarge?.copyWith(color: context.ace.textMuted),
          ),

          const AceSectionHeader(title: 'Cores da marca'),
          const Wrap(spacing: AceSpacing.x2, runSpacing: AceSpacing.x2, children: [
            _Swatch('Verde 600', AceColors.green600, Colors.white),
            _Swatch('Verde 800', AceColors.green800, Colors.white),
            _Swatch('Verde 50', AceColors.green50, AceColors.green800),
            _Swatch('Âmbar sol', AceColors.amber500, AceColors.amber900),
            _Swatch('Tinta', AceColors.ink900, Colors.white),
            _Swatch('Névoa', AceColors.mist50, AceColors.ink900),
          ]),

          const AceSectionHeader(title: 'Tipografia'),
          AceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Título grande', style: context.text.headlineMedium),
                Text('Título de seção', style: context.text.titleLarge),
                Text('Texto de leitura em campo', style: context.text.bodyLarge),
                Text('Texto de apoio e legendas', style: context.text.bodySmall),
              ],
            ),
          ),

          const AceSectionHeader(title: 'Espaçamento e raios'),
          Wrap(
            spacing: AceSpacing.x3,
            runSpacing: AceSpacing.x3,
            children: const [
              _Space('x1', AceSpacing.x1),
              _Space('x2', AceSpacing.x2),
              _Space('x3', AceSpacing.x3),
              _Space('x4', AceSpacing.x4),
              _Space('x5', AceSpacing.x5),
              _Space('x6', AceSpacing.x6),
            ],
          ),

          const AceSectionHeader(title: 'Botões'),
          AceButton(label: 'Registrar visita', icon: Icons.add_task, loading: _loading, onPressed: _fakeSave),
          const SizedBox(height: AceSpacing.x3),
          AceButton(label: 'Ver no mapa', icon: Icons.map_outlined, variant: AceButtonVariant.secondary, onPressed: () {}),
          const SizedBox(height: AceSpacing.x3),
          Row(children: [
            Expanded(child: AceButton(label: 'Cancelar', variant: AceButtonVariant.ghost, onPressed: () {})),
            const SizedBox(width: AceSpacing.x3),
            Expanded(child: AceButton(label: 'Excluir', variant: AceButtonVariant.danger, onPressed: () {})),
          ]),

          const AceSectionHeader(title: 'Perfil de acesso'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'agente', label: Text('Agente'), icon: Icon(Icons.person_outline)),
              ButtonSegment(value: 'supervisor', label: Text('Supervisor'), icon: Icon(Icons.groups_outlined)),
            ],
            selected: {_profile},
            onSelectionChanged: (s) => setState(() => _profile = s.first),
          ),

          const AceSectionHeader(title: 'Campos de texto'),
          const AceTextField(
            label: 'Endereço do imóvel',
            hint: 'Rua, número e quadra',
            icon: Icons.place_outlined,
            helper: 'Use o endereço do cadastro do lote.',
          ),
          const SizedBox(height: AceSpacing.x4),
          const AceTextField(
            label: 'Matrícula do agente',
            error: 'Informe a matrícula com 6 dígitos.',
            keyboardType: TextInputType.number,
          ),

          const AceSectionHeader(title: 'Status de visita'),
          Wrap(spacing: AceSpacing.x2, runSpacing: AceSpacing.x2, children: [
            for (final s in AceStatus.values) AceStatusBadge(status: s),
          ]),
          const SizedBox(height: AceSpacing.x4),
          Text('Selecionar status', style: context.text.titleSmall),
          const SizedBox(height: AceSpacing.x2),
          AceStatusSelector(value: _status, onChanged: (s) => setState(() => _status = s)),

          const AceSectionHeader(title: 'Resumo do dia', actionLabel: 'Ver tudo'),
          const Row(children: [
            Expanded(child: AceStatCard(value: '42', label: 'Visitas feitas', icon: Icons.check_circle_outline)),
            SizedBox(width: AceSpacing.x3),
            Expanded(child: AceStatCard(value: '8', label: 'Pendentes', icon: Icons.schedule)),
          ]),

          const AceSectionHeader(title: 'Lista de visitas'),
          const AceVisitTile(lot: '07', address: 'Rua das Mangabas, 120', detail: 'Quadra 12 · 09:40', status: AceStatus.visitado),
          const SizedBox(height: AceSpacing.x2),
          const AceVisitTile(lot: '08', address: 'Rua das Mangabas, 134', detail: 'Quadra 12 · 09:55', status: AceStatus.fechado),
          const SizedBox(height: AceSpacing.x2),
          const AceVisitTile(lot: '09', address: 'Av. Jatobá, 18', detail: 'Quadra 13 · 10:10', status: AceStatus.comFoco),

          const AceSectionHeader(title: 'Estado vazio'),
          AceCard(
            child: AceEmptyState(
              icon: Icons.map_outlined,
              title: 'Nenhuma visita hoje',
              message: 'Escolha uma quadra no mapa para iniciar o roteiro do dia.',
              actionLabel: 'Abrir mapa',
              onAction: () => AceSnackbar.show(context, 'Mapa indisponível sem conexão', type: AceFeedback.error),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _nav,
        onDestinationSelected: (i) => setState(() => _nav = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Visitas'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, this.onColor);
  final String name;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 64,
      padding: const EdgeInsets.all(AceSpacing.x2),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AceRadius.md),
        border: Border.all(color: context.ace.line),
      ),
      child: Text(name, style: context.text.labelMedium?.copyWith(color: onColor)),
    );
  }
}

class _Space extends StatelessWidget {
  const _Space(this.name, this.size);
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AceSpacing.x1),
        Text('$name · ${size.toInt()}', style: context.text.bodySmall),
      ],
    );
  }
}
