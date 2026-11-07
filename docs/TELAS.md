# Tema e protótipo de telas — ACE CONTROL

## Tema do app

**Conceito "Cerrado"**: verde-folha profundo (marca) e âmbar de sol (acento), neutros levemente
esverdeados. O app é usado a pé, sob sol forte, muitas vezes com uma mão só.

| Token | Valor | Uso |
|---|---|---|
| Verde 600 | `#1B6B4F` | Cor primária, botões, foco |
| Verde 800 / 50 | `#0F4A36` / `#E6F3EC` | Textos sobre fundo claro de marca / contêineres |
| Âmbar sol | `#E8A317` | Acento (uso pontual) |
| Tinta | `#12201D` | Texto |
| Névoa | `#F2F5F3` | Fundo das telas |
| Tipografia | Sora (títulos) + Public Sans (texto) | 12 estilos; mínimo 12 sp |

Regras: alvos de toque ≥ 52 dp · bordas em vez de sombras · status sempre com cor + ícone + texto ·
contraste AA (4.5:1) testado nos temas claro e escuro.

Status de visita: **Pendente · Visitado · Fechado · Recusado · Recuperado · Com foco**.

## Mapa de telas

```
Splash/Gate ──(sem auth code)──▶ Login ──(sucesso)──▶ Home
     └────────(com auth code)───────────────────────▶ Home
Home (abas):  Início · Mapa* · Visitas · Perfil
Início ──toque na visita──▶ Folha "Registrar visita"
Perfil ──Sair──▶ Login
(*) Mapa: protótipo (placeholder "em desenvolvimento")
```

Implementado: Gate, Login, Home (Início, Visitas, Perfil, folha de registro). Protótipo: Mapa.

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
