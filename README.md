# ACE CONTROL — Design System (Flutter)

Primeira etapa do ecossistema mobile do ACE CONTROL: tokens de design, tema
claro/escuro e biblioteca de componentes para os apps de **agente** e **supervisor**.

## Rodando

O repositório traz só `lib/`, `test/` e `pubspec.yaml`. Gere as pastas de plataforma uma vez:

```bash
flutter create . --platforms=android,ios
flutter pub get
flutter analyze
flutter test
flutter run
```

## Estrutura

```
lib/
  design_system/
    design_system.dart      # único import usado pelas telas
    tokens/                 # cores, tipografia, espaçamento/raios/movimento, status
    theme/ace_theme.dart    # ThemeData claro/escuro + extensão AceSemantic (context.ace)
    components/             # AceButton, AceCard, AceTextField, AceStatusBadge, ...
  showcase/                 # galeria viva (telas de demonstração)
  main.dart
test/design_system_test.dart
```

## Princípios

1. **Campo primeiro**: alvos de toque de 52 dp, texto ≥ 12 sp, bordas em vez de sombras (sol forte).
2. **Cor nunca sozinha**: todo status tem cor + ícone + texto.
3. **Contraste AA**: testado automaticamente (4.5:1) nos dois temas.
4. **Tokens → tema → componentes**: telas não usam cores ou números soltos.
5. **Marca white-label**: trocar a identidade de um município = editar `ace_colors.dart`.

## Tokens

| Grupo | Arquivo | Conteúdo |
|---|---|---|
| Cor | `ace_colors.dart` | Verde Cerrado, Âmbar Sol, neutros claro/escuro, feedback |
| Tipografia | `ace_typography.dart` | Sora (títulos) + Public Sans (texto), 12 estilos |
| Espaço | `ace_spacing.dart` | Grade de 4 dp (x1–x8), `touch`, `page`, raios, movimento |
| Status | `ace_status.dart` | Pendente, Visitado, Fechado, Recusado, Recuperado, Com foco |

## Componentes

`AceButton` (4 variantes, loading) · `AceCard` · `AceTextField` · `AceStatusBadge` ·
`AceStatusSelector` · `AceStatCard` · `AceVisitTile` · `AceSectionHeader` ·
`AceEmptyState` · `AceSnackbar`

## Próximas etapas sugeridas

Telas do agente (roteiro, mapa de lotes, registro de visita), telas do supervisor
(painel por área) e integração com a API FastAPI.
