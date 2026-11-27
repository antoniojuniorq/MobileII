# Tema e protótipo de telas — ACE CONTROL

## Tema do app

**v3 "Frost and slate"** (escolhida pela Taste Skill para serviços de saúde): fundo gelo, tinta
ardósia e petróleo como cor de ação; Schibsted Grotesk em todo o texto. Vermelho, verde e cinza
ficam só para a situação dos lotes. O app é usado a pé, sob sol forte, muitas vezes com uma mão só.

| Token | Valor | Uso |
|---|---|---|
| Petróleo 600 | `#0D7480` | Cor de ação, botões, foco |
| Petróleo 700 / 50 | `#0A5C66` / `#E3F1F2` | Topo do login, textos sobre contêiner / contêineres |
| Âmbar | `#F2A93B` | Atenção pontual |
| Ardósia | `#1F3038` | Texto |
| Gelo | `#F7F9FA` | Fundo das telas |
| Lote | `#D5432F` / `#239A5E` / `#8E989E` | A visitar / visitado / recusa ou ausente |
| Tipografia | Schibsted Grotesk | 12 estilos; mínimo 12 sp |

Regras: alvos de toque ≥ 52 dp · bordas em vez de sombras · status sempre com cor + ícone + texto ·
contraste AA (4.5:1) testado nos temas claro e escuro.

Status de visita: **Pendente · Visitado · Fechado · Recusado · Recuperado · Com foco**.

## Mapa de telas

```
Splash/Gate ──(sem sessão)──▶ Login ─┬─(agente)──────▶ Escolha da quadra ──▶ Home do agente
     │                               └─(supervisor)──▶ Painel do supervisor
     └──(com sessão)──▶ agente com quadra salva → Home · sem quadra → Escolha · supervisor → Painel
Home do agente (abas):  Início · Mapa 3D · Visitas · Perfil (trocar quadra, sair)
Mapa 3D ──toque no conjunto──▶ aproxima ──toque na casa──▶ Folha "Lote N"
Folha "Lote N": Visitado (criadouros, larvas, animais, locais com focos) | Recusado / não atendido
Painel do supervisor (abas): Painel · Mapa 3D (só leitura) · Perfil
```

### Mapa 3D da quadra (`AceIsoMap`)

Cada lote é o contorno real da planta da Prefeitura, levantado como um bloco liso, numa vista
inclinada com o norte para cima. **Vermelho** = a visitar, **verde** = visitado, **cinza** = recusa
ou ninguém em casa; a legenda repete cor + ícone + quantidade. Pinça e arrasto aproximam; os
atalhos "QI 01, QI 02…" levam direto ao conjunto. Com o mapa afastado o toque aproxima o
conjunto; aproximado, o toque abre o lote (alvo grande o bastante para o dedo).

### Login

Duas entradas lado a lado (`AceChoiceCard`): **Agente de campo** (registrar visitas) e
**Supervisor** (acompanhar a quadra). O botão diz para onde vai: "Entrar como agente".
Correção do teclado: o campo de senha usa teclado de texto para senha, sem sugestões nem
correção, com botão de mostrar a senha; o "próximo" da matrícula reabre o teclado já no modo
texto (antes, em vários Android, o teclado numérico da matrícula continuava na senha).

## Wireframes

### Login

```
┌──────────────────────────┐
│ (ícone)                  │
│ ACE CONTROL              │
│ Entre com sua matrícula  │
│ para ver o roteiro do dia│
│                          │
│ Matrícula                │
│ [ 🪪  123456           ] │
│ Senha                    │
│ [ 🔒  ••••••           ] │
│ ┌──────────────────────┐ │
│ │ ⚠ Matrícula ou senha │ │   ← AceInlineMessage (só no erro)
│ │   incorreta.         │ │
│ └──────────────────────┘ │
│ [        Entrar        ] │
└──────────────────────────┘
```

### Home — Início

```
┌──────────────────────────┐
│ ACE CONTROL              │
├──────────────────────────┤
│ Bom dia, Antonio         │   GET /me
│ Área 07 · Palmas - TO    │
│ ┌──────────────────────┐ │
│ │ Meta do dia  6 de 10 │ │   GET /summary/today
│ │ ██████░░░░           │ │   AceProgressBar
│ └──────────────────────┘ │
│ [✓ 6 ][⏱ 4 ][🐛 1 ]      │   AceStatCard x3
│ Roteiro de hoje  Ver tudo│   AceSectionHeader
│ [12] Rua dos Buritis,61  │   AceVisitTile + AceStatusBadge
│      Quadra 14   Pendente│   GET /visits
│ [13] ...                 │
├──────────────────────────┤
│ Início  Mapa  Visitas  Perfil │  NavigationBar
└──────────────────────────┘
```

### Folha "Registrar visita"

```
┌──────────────────────────┐
│ Lote 12                  │
│ Rua dos Buritis, 61 · Qd 14│
│ Resultado da visita      │
│ (Pendente)(Visitado)     │   AceStatusSelector
│ (Fechado)(Recusado)      │
│ (Recuperado)(Com foco)   │
│ Observação [___________] │   AceTextField
│ [     Salvar visita    ] │   PATCH /visits/{id}
└──────────────────────────┘
```

### Estados da Home

- **Carregando:** indicador de progresso centralizado.
- **Erro:** `AceEmptyState` "Não foi possível carregar" + botão "Tentar de novo".
- **Sem visitas:** `AceEmptyState` "Nenhuma visita hoje".
- **Falha ao atualizar com dados na tela:** `AceInlineMessage` no topo, conteúdo mantido.
- **Sessão expirada (401 `unauthorized`):** limpa o auth code e volta ao Login.

## Próximas telas (a prototipar)

Mapa de lotes · detalhe da visita · histórico · visão do supervisor.
