# API do ACE CONTROL — requests e responses

Implementada pelo **MockServer** (`server/`). Os exemplos abaixo são respostas reais do servidor.
Swagger interativo: `http://localhost:8000/docs`.

- **Base URL:** `http://localhost:8000` (emulador Android: `http://10.0.2.2:8000`)
- **Formato:** JSON, UTF-8
- **Autenticação:** `Authorization: Bearer <auth_code>` (o `auth_code` vem do login)
- **Credenciais de teste:** agente `123456` / `ace123` · supervisor `654321` / `sup123`

## Formato de erro (todas as rotas)

```json
{ "error": { "code": "invalid_credentials", "message": "Matrícula ou senha incorreta." } }
```

`message` já está pronta para exibir ao usuário. `code` é estável e serve para decisões no app.

| HTTP | `code` | Quando |
|---|---|---|
| 401 | `invalid_credentials` | Login com matrícula/senha incorretas |
| 403 | `wrong_profile` | Matrícula certa, mas entrada errada (ex.: agente tentando entrar como supervisor) |
| 403 | `forbidden` | Supervisor tentando registrar visita |
| 404 | `quadra_not_found` / `lote_not_found` | Quadra ou lote inexistente |
| 401 | `unauthorized` | Sem `Authorization`, auth code inválido ou expirado (o app volta ao Login) |
| 404 | `visit_not_found` | Visita inexistente |
| 404 | `not_found` | Rota inexistente |
| 422 | `validation_error` | Corpo inválido (traz `fields`) |

Exemplo de `422`:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Dados inválidos.",
    "fields": [{ "field": "senha", "message": "Field required" }]
  }
}
```

## Valores de `status` da visita

`pendente` · `visitado` · `fechado` · `recusado` · `recuperado` · `com_foco`

## Endpoints

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/health` | não | Verifica se o servidor está no ar |
| POST | `/auth/login` | não | Login; devolve `auth_code` |
| POST | `/auth/logout` | sim | Encerra a sessão |
| GET | `/me` | sim | Dados do agente logado |
| GET | `/summary/today` | sim | Resumo do dia (meta, feitas, pendentes, focos) |
| GET | `/visits` | sim | Lista de visitas do dia (`?status=pendente` filtra) |
| GET | `/visits/{id}` | sim | Detalhe de uma visita |
| PATCH | `/visits/{id}` | sim | Registra o resultado da visita |
| GET | `/quadras` | sim | Quadras de atuação com o andamento do dia |
| GET | `/quadras/{id}` | sim | Planta da quadra: conjuntos, lotes (posição e situação) e áreas livres |
| POST | `/quadras/{id}/lotes/{lote}/visita` | sim (agente) | Registra a visita do lote |
| POST | `/dev/reset` | não | Restaura os dados iniciais (só no mock) |

---

### POST `/auth/login`

Request:

```json
{ "matricula": "123456", "senha": "ace123" }
```

Response `200`:

```json
{
  "auth_code": "qauN_LMOI6aoNhUj9lBp-MS4EnTyCFFN",
  "expires_at": "2026-11-07T12:48:01.895155Z",
  "agent": {
    "id": 1,
    "nome": "Antonio Junior",
    "matricula": "123456",
    "municipio": "Palmas - TO",
    "area": "Área 07 · Quadras 12 a 14"
  }
}
```

Response `401` (senha errada):

```json
{ "error": { "code": "invalid_credentials", "message": "Matrícula ou senha incorreta." } }
```

O app guarda o `auth_code` no storage. Ao abrir, se houver `auth_code` guardado, vai direto para a Home.

### POST `/auth/logout`

Header: `Authorization: Bearer <auth_code>` — sem corpo. Response `204` (sem corpo).

### GET `/me`

Response `200`:

```json
{
  "id": 1,
  "nome": "Antonio Junior",
  "matricula": "123456",
  "municipio": "Palmas - TO",
  "area": "Área 07 · Quadras 12 a 14"
}
```

Sem sessão válida, `401`:

```json
{ "error": { "code": "unauthorized", "message": "Sessão expirada. Entre novamente." } }
```

### GET `/summary/today`

Response `200`:

```json
{
  "date": "2026-11-07",
  "goal": 10,
  "visits_total": 10,
  "visits_done": 6,
  "visits_pending": 4,
  "focos_found": 1
}
```

`visits_done` = visitas com status diferente de `pendente`. Usado na Home (meta do dia e cartões).

### GET `/visits`

Query opcional: `status` (um dos valores acima). Response `200` (exemplo com `?status=pendente`, 2 primeiros itens):

```json
[
  {
    "id": 6,
    "lote": "12",
    "endereco": "Rua dos Buritis, 61",
    "quadra": "Quadra 14",
    "horario": null,
    "status": "pendente",
    "observacao": null
  },
  {
    "id": 7,
    "lote": "13",
    "endereco": "Rua dos Buritis, 77",
    "quadra": "Quadra 14",
    "horario": null,
    "status": "pendente",
    "observacao": null
  }
]
```

`horario` (`HH:MM`) é `null` enquanto a visita está pendente.

### GET `/visits/{id}`

Response `200`: um objeto de visita (mesmo formato acima). Response `404`:

```json
{ "error": { "code": "visit_not_found", "message": "Visita não encontrada." } }
```

### PATCH `/visits/{id}`

Request (`observacao` é opcional, máx. 280 caracteres):

```json
{ "status": "com_foco", "observacao": "Pneus com água parada no quintal" }
```

Response `200`:

```json
{
  "id": 6,
  "lote": "12",
  "endereco": "Rua dos Buritis, 61",
  "quadra": "Quadra 14",
  "horario": "09:41",
  "status": "com_foco",
  "observacao": "Pneus com água parada no quintal"
}
```

Se a visita estava sem horário, o servidor preenche com a hora atual. Voltar para `pendente` limpa o horário.
Status fora da lista responde `422`.

## Perfis no login

`POST /auth/login` aceita `perfil`: `"agente"` (padrão) ou `"supervisor"`, a entrada escolhida na
tela. Se a matrícula existir com outro perfil, responde `403 wrong_profile`. O `agent` devolvido
traz `perfil`.

```json
{ "matricula": "654321", "senha": "sup123", "perfil": "supervisor" }
```

## Quadras e lotes

A Quadra 1106 Sul (ARSE 112, Palmas - TO) vem da planta de parcelamento da Prefeitura (março de
2015) em forma esquemática: 36 conjuntos (filas duplas de lotes por alameda), 480 lotes. Medidas
em testadas de lote (~12 m); `x` cresce para leste, `y` para sul.

Situação do lote (`status`): `pendente` (vermelho no mapa), `visitado` (verde), `sem_acesso`
(cinza: recusa ou ninguém em casa).

### GET `/quadras/{id}` (trecho)

```json
{
  "id": "1106", "nome": "Quadra 1106 Sul", "bairro": "ARSE 112 · Palmas - TO",
  "total_lotes": 480, "visitados": 6, "sem_acesso": 2, "pendentes": 472,
  "largura": 48, "altura": 65,
  "areas": [{ "nome": "Área verde · esporte e lazer", "x": 15, "y": 23, "w": 18, "h": 14 }],
  "conjuntos": [{
    "id": "AL01-0203", "nome": "Alameda 1", "x": 2, "y": 3, "w": 5, "h": 4,
    "lotes": [{
      "id": "AL01-L04", "numero": 4, "x": 5, "y": 3, "w": 1, "d": 2, "status": "visitado",
      "visita": { "resultado": "visitado", "horario": "08:10", "agente": "Antonio Junior",
                  "criadouros": 3, "larvas": 12, "animais": 2, "focos": 1 }
    }]
  }]
}
```

### POST `/quadras/{id}/lotes/{lote}/visita`

```json
{ "resultado": "visitado", "criadouros": 2, "larvas": 15, "animais": 0, "focos": 1 }
```

`resultado`: `visitado` ou `recusado` (recusa ou não atendido → lote `sem_acesso`, números zerados).
Números negativos respondem `422`. Só o perfil agente registra (`403 forbidden` para supervisor).
Responde o lote atualizado.

## Mapa tela → endpoints

| Tela | Chamadas |
|---|---|
| Login (agente ou supervisor) | `POST /auth/login` |
| Escolha da quadra | `GET /quadras` |
| Home do agente / Mapa 3D / Visitas | `GET /me`, `GET /quadras/{id}` |
| Registrar visita (folha do lote) | `POST /quadras/{id}/lotes/{lote}/visita` |
| Painel do supervisor | `GET /me`, `GET /quadras`, `GET /quadras/{id}` |
| Perfil — Sair | `POST /auth/logout` |

As rotas `/summary/today` e `/visits` continuam no servidor, mas o app passou a usar as de quadra.
No Flutter, tudo passa pelo pacote `ace_core` (`AuthRepository`, `AgentRepository`, `QuadrasRepository`).
