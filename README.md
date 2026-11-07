# ACE CONTROL — ecossistema mobile (Flutter)

Monorepo com a estrutura do workspace (`ace_control.code-workspace`):

```
apps/mobile/            App Flutter (cenas Login e Home)
packages/core/          ace_core: HTTP, sessão (auth code), modelos e repositórios
packages/design_system/ ace_design_system: tokens, tema e componentes
  └─ example/           Sample app do Design System (galeria viva)
server/                 MockServer (FastAPI) com a API simulada
docs/                   API.md (requests/responses) e TELAS.md (tema e protótipo)
scripts/                setup.ps1 e run_server.ps1 (Windows)
```

## Padrão de projeto (cenas)

Cada tela é uma **cena** em `apps/mobile/lib/scenes/<nome>/`:

```
login/
  login_scene.dart        # UI (só desenha e repassa ações)
  login_view_model.dart   # estado + lógica; fala com o Core
home/
  home_scene.dart
  home_view_model.dart
  widgets/                # partes da cena
```

- ViewModels estendem `SceneViewModel` (ChangeNotifier seguro após `dispose`).
- A cena escuta o ViewModel com `ListenableBuilder`; navegação em `lib/navigation.dart`.
- Cenas só usam componentes do **Design System** e dados do **Core** — nunca `http` direto.
- Fluxo de sessão: sem auth code → Login; Login ok → guarda auth code → Home; abrir o app com
  auth code → Home direto; `401 unauthorized` → limpa o storage e volta ao Login.

## Como rodar (Windows)

Pré-requisitos: Flutter, Python 3.11+ e Git.

```powershell
# 1) uma vez: gera android/ios e baixa dependências
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1

# 2) terminal 1: MockServer
powershell -ExecutionPolicy Bypass -File scripts\run_server.ps1

# 3) terminal 2: app (emulador Android)
cd apps\mobile
flutter run
```

Login de teste: matrícula `123456`, senha `ace123`.

- **Celular físico:** `flutter run --dart-define=API_BASE_URL=http://IP_DO_PC:8000` (mesma rede Wi-Fi).
- **Sample app do Design System:** `cd packages\design_system\example; flutter run`.

## Testes

```powershell
cd server;                       python -m pytest -q
cd packages\design_system;       flutter test
cd packages\design_system\example; flutter test
cd packages\core;                flutter test
cd apps\mobile;                  flutter test
```

O CI (`.github/workflows/ci.yml`) roda tudo isso a cada push.
