"""MockServer do ACE CONTROL (FastAPI, dados em memória).

Rodar:  uvicorn main:app --reload --host 0.0.0.0 --port 8000
Docs interativas (Swagger): http://localhost:8000/docs
Login de teste: agente "123456" / "ace123" · supervisor "654321" / "sup123"
"""
from __future__ import annotations

import json
import secrets
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Literal, Optional

from fastapi import Depends, FastAPI, Header, Query, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, Field
from starlette.exceptions import HTTPException as StarletteHTTPException

VisitStatus = Literal[
    "pendente", "visitado", "fechado", "recusado", "recuperado", "com_foco"
]

# ----------------------------------------------------------------- modelos


Perfil = Literal["agente", "supervisor"]


class LoginRequest(BaseModel):
    matricula: str = Field(min_length=1, examples=["123456"])
    senha: str = Field(min_length=1, examples=["ace123"])
    perfil: Perfil = Field("agente", description="Entrada escolhida no app")


class Agent(BaseModel):
    id: int
    nome: str
    matricula: str
    municipio: str
    area: str
    perfil: Perfil = "agente"


class LoginResponse(BaseModel):
    auth_code: str
    expires_at: datetime
    agent: Agent


class Visit(BaseModel):
    id: int
    lote: str
    endereco: str
    quadra: str
    horario: Optional[str] = Field(None, description="HH:MM; nulo se pendente")
    status: VisitStatus
    observacao: Optional[str] = None


class VisitUpdate(BaseModel):
    status: VisitStatus
    observacao: Optional[str] = Field(None, max_length=280)


class Summary(BaseModel):
    date: date
    goal: int
    visits_total: int
    visits_done: int
    visits_pending: int
    focos_found: int


class ErrorBody(BaseModel):
    code: str
    message: str
    fields: Optional[list[dict]] = None


class ErrorResponse(BaseModel):
    error: ErrorBody


# ------------------------------------------------------------ dados (seed)

AGENT = {
    "id": 1,
    "nome": "Antonio Junior",
    "matricula": "123456",
    "municipio": "Palmas - TO",
    "area": "Área 07 · Quadras 12 a 14",
    "perfil": "agente",
}
SUPERVISOR = {
    "id": 2,
    "nome": "Marina Lopes",
    "matricula": "654321",
    "municipio": "Palmas - TO",
    "area": "Supervisão · Região Sul",
    "perfil": "supervisor",
}
# matrícula -> (usuário, senha)
USERS = {
    AGENT["matricula"]: (AGENT, "ace123"),
    SUPERVISOR["matricula"]: (SUPERVISOR, "sup123"),
}
SESSION_HOURS = 12


def _seed_visits() -> dict[int, dict]:
    rows = [
        ("07", "Rua das Mangabas, 120", "Quadra 12", "08:40", "visitado"),
        ("08", "Rua das Mangabas, 134", "Quadra 12", "09:05", "fechado"),
        ("09", "Av. Jatobá, 18", "Quadra 13", "09:30", "com_foco"),
        ("10", "Av. Jatobá, 32", "Quadra 13", "09:50", "visitado"),
        ("11", "Rua dos Buritis, 45", "Quadra 13", "10:15", "recusado"),
        ("12", "Rua dos Buritis, 61", "Quadra 14", None, "pendente"),
        ("13", "Rua dos Buritis, 77", "Quadra 14", None, "pendente"),
        ("14", "Rua das Seriemas, 9", "Quadra 14", None, "pendente"),
        ("15", "Rua das Seriemas, 23", "Quadra 14", None, "pendente"),
        ("16", "Rua das Seriemas, 40", "Quadra 14", "11:05", "recuperado"),
    ]
    return {
        i: {
            "id": i,
            "lote": lote,
            "endereco": end,
            "quadra": qd,
            "horario": hor,
            "status": st,
            "observacao": None,
        }
        for i, (lote, end, qd, hor, st) in enumerate(rows, start=1)
    }


VISITS: dict[int, dict] = _seed_visits()
SESSIONS: dict[str, tuple[datetime, dict]] = {}  # auth_code -> (expiração, usuário)
GOAL = 10

# ------------------------------------------------------------------- erros


class ApiError(Exception):
    def __init__(self, status: int, code: str, message: str):
        self.status, self.code, self.message = status, code, message


def _error(status: int, code: str, message: str, **extra) -> JSONResponse:
    return JSONResponse(
        status_code=status,
        content={"error": {"code": code, "message": message, **extra}},
    )


app = FastAPI(title="ACE CONTROL - MockServer", version="1.0.0")
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)


@app.exception_handler(ApiError)
async def _api_error(_: Request, exc: ApiError):
    return _error(exc.status, exc.code, exc.message)


@app.exception_handler(RequestValidationError)
async def _validation_error(_: Request, exc: RequestValidationError):
    fields = [
        {"field": ".".join(str(p) for p in e["loc"][1:]), "message": e["msg"]}
        for e in exc.errors()
    ]
    return _error(422, "validation_error", "Dados inválidos.", fields=fields)


@app.exception_handler(StarletteHTTPException)
async def _http_error(_: Request, exc: StarletteHTTPException):
    code = "not_found" if exc.status_code == 404 else "http_error"
    return _error(exc.status_code, code, str(exc.detail))


# -------------------------------------------------------------------- auth


def current_agent(authorization: Optional[str] = Header(None)) -> dict:
    expired = ApiError(401, "unauthorized", "Sessão expirada. Entre novamente.")
    if not authorization or not authorization.startswith("Bearer "):
        raise expired
    code = authorization.removeprefix("Bearer ").strip()
    session = SESSIONS.get(code)
    if session is None or session[0] < datetime.now(timezone.utc):
        SESSIONS.pop(code, None)
        raise expired
    return session[1]


@app.get("/health", tags=["infra"])
def health():
    return {"status": "ok"}


@app.post(
    "/auth/login",
    response_model=LoginResponse,
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
    tags=["auth"],
)
def login(body: LoginRequest):
    user, password = USERS.get(body.matricula, (None, None))
    if user is None or body.senha != password:
        raise ApiError(401, "invalid_credentials", "Matrícula ou senha incorreta.")
    if user["perfil"] != body.perfil:
        nome = "supervisor" if body.perfil == "supervisor" else "agente de campo"
        raise ApiError(403, "wrong_profile", f"Esta matrícula não entra como {nome}.")
    code = secrets.token_urlsafe(24)
    expires = datetime.now(timezone.utc) + timedelta(hours=SESSION_HOURS)
    SESSIONS[code] = (expires, user)
    return {"auth_code": code, "expires_at": expires, "agent": user}


@app.post("/auth/logout", status_code=204, tags=["auth"])
def logout(authorization: Optional[str] = Header(None), _=Depends(current_agent)):
    SESSIONS.pop((authorization or "").removeprefix("Bearer ").strip(), None)
    return Response(status_code=204)


@app.get("/me", response_model=Agent, tags=["agente"])
def me(agent=Depends(current_agent)):
    return agent


# ------------------------------------------------------------------ visitas


@app.get("/summary/today", response_model=Summary, tags=["visitas"])
def summary_today(_=Depends(current_agent)):
    visits = list(VISITS.values())
    pending = sum(v["status"] == "pendente" for v in visits)
    return {
        "date": date.today(),
        "goal": GOAL,
        "visits_total": len(visits),
        "visits_done": len(visits) - pending,
        "visits_pending": pending,
        "focos_found": sum(v["status"] == "com_foco" for v in visits),
    }


@app.get("/visits", response_model=list[Visit], tags=["visitas"])
def list_visits(
    status: Optional[VisitStatus] = Query(None, description="Filtra por status"),
    _=Depends(current_agent),
):
    items = [v for v in VISITS.values() if status is None or v["status"] == status]
    return items


@app.get(
    "/visits/{visit_id}",
    response_model=Visit,
    responses={404: {"model": ErrorResponse}},
    tags=["visitas"],
)
def get_visit(visit_id: int, _=Depends(current_agent)):
    visit = VISITS.get(visit_id)
    if visit is None:
        raise ApiError(404, "visit_not_found", "Visita não encontrada.")
    return visit


@app.patch(
    "/visits/{visit_id}",
    response_model=Visit,
    responses={404: {"model": ErrorResponse}, 422: {"model": ErrorResponse}},
    tags=["visitas"],
)
def update_visit(visit_id: int, body: VisitUpdate, _=Depends(current_agent)):
    visit = VISITS.get(visit_id)
    if visit is None:
        raise ApiError(404, "visit_not_found", "Visita não encontrada.")
    visit["status"] = body.status
    visit["observacao"] = body.observacao
    if body.status == "pendente":
        visit["horario"] = None
    elif visit["horario"] is None:
        visit["horario"] = datetime.now().strftime("%H:%M")
    return visit


# ------------------------------------------------------------------ quadras
#
# Quadra 1106 Sul (ARSE 112, Palmas - TO). A planta (data/quadra_1106.json) foi
# extraída da planta de parcelamento da Prefeitura (PDF vetorial, março de 2015):
# cada lote é o polígono fechado pelas linhas da camada LOTE do CAD, com o número
# desenhado dentro dele, agrupado na sua Quadra Interna (QI/QC). Unidade: ponto do
# PDF (~1 m); x cresce para leste, y para sul.

LoteStatus = Literal["pendente", "visitado", "sem_acesso"]
Resultado = Literal["visitado", "recusado"]
Ponto = tuple[float, float]


class VisitaLote(BaseModel):
    resultado: Resultado
    horario: str
    agente: str
    criadouros: int = 0
    larvas: int = 0
    animais: int = 0
    focos: int = 0


class Lote(BaseModel):
    id: str
    numero: str = Field(description='Como está na planta: "7", "15-A"')
    poly: list[Ponto] = Field(description="Contorno do lote")
    status: LoteStatus
    visita: Optional[VisitaLote] = None


class Conjunto(BaseModel):
    id: str
    nome: str = Field(examples=["QI 16"])
    alameda: Optional[str] = Field(None, examples=["Alameda 4"])
    lotes: list[Lote]


class AreaLivre(BaseModel):
    nome: str
    tipo: Literal["park", "building"]
    poly: list[Ponto]


class QuadraResumo(BaseModel):
    id: str
    nome: str
    bairro: str
    total_lotes: int
    visitados: int
    sem_acesso: int
    pendentes: int


class Quadra(QuadraResumo):
    largura: float
    altura: float
    areas: list[AreaLivre]
    conjuntos: list[Conjunto]


class VisitaRequest(BaseModel):
    resultado: Resultado
    criadouros: int = Field(0, ge=0, le=999)
    larvas: int = Field(0, ge=0, le=9999)
    animais: int = Field(0, ge=0, le=99)
    focos: int = Field(0, ge=0, le=999)


_PLANTA_1106 = Path(__file__).parent / "data" / "quadra_1106.json"

# visitas já feitas no começo do dia (demonstração)
_SEED_LOTES = {
    "QI01-L01": ("visitado", "07:40", 2, 0, 1, 0),
    "QI01-L02": ("visitado", "07:52", 0, 0, 0, 0),
    "QI01-L03": ("recusado", "08:01", 0, 0, 0, 0),
    "QI01-L04": ("visitado", "08:10", 3, 12, 2, 1),
    "QI01-L06": ("visitado", "08:24", 1, 0, 0, 0),
    "QI01-L07": ("recusado", "08:31", 0, 0, 0, 0),
    "QI02-L01": ("visitado", "08:45", 0, 0, 1, 0),
    "QI02-L02": ("visitado", "08:58", 4, 30, 0, 2),
}


def _build_1106() -> dict:
    planta = json.loads(_PLANTA_1106.read_text(encoding="utf-8"))
    for c in planta["conjuntos"]:
        for lote in c["lotes"]:
            lote["status"] = "pendente"
            lote["visita"] = None
    return {
        "id": "1106",
        "nome": "Quadra 1106 Sul",
        "bairro": "ARSE 112 · Palmas - TO",
        **planta,
    }


def _apply_visit(lote, resultado, horario, agente, cri=0, lar=0, ani=0, foc=0):
    visitado = resultado == "visitado"
    lote["status"] = "visitado" if visitado else "sem_acesso"
    lote["visita"] = {
        "resultado": resultado,
        "horario": horario,
        "agente": agente,
        "criadouros": cri if visitado else 0,
        "larvas": lar if visitado else 0,
        "animais": ani if visitado else 0,
        "focos": foc if visitado else 0,
    }


def _seed_quadras() -> dict[str, dict]:
    q = _build_1106()
    by_id = {lote["id"]: lote for c in q["conjuntos"] for lote in c["lotes"]}
    for lote_id, (res, hor, cri, lar, ani, foc) in _SEED_LOTES.items():
        _apply_visit(by_id[lote_id], res, hor, AGENT["nome"], cri, lar, ani, foc)
    return {q["id"]: q}


def _resumo(q: dict) -> dict:
    lotes = [lote for c in q["conjuntos"] for lote in c["lotes"]]

    def count(status: str) -> int:
        return sum(lote["status"] == status for lote in lotes)

    return {
        "id": q["id"],
        "nome": q["nome"],
        "bairro": q["bairro"],
        "total_lotes": len(lotes),
        "visitados": count("visitado"),
        "sem_acesso": count("sem_acesso"),
        "pendentes": count("pendente"),
    }


QUADRAS: dict[str, dict] = _seed_quadras()


def _quadra_or_404(quadra_id: str) -> dict:
    q = QUADRAS.get(quadra_id)
    if q is None:
        raise ApiError(404, "quadra_not_found", "Quadra não encontrada.")
    return q


@app.get("/quadras", response_model=list[QuadraResumo], tags=["quadras"])
def list_quadras(_=Depends(current_agent)):
    return [_resumo(q) for q in QUADRAS.values()]


@app.get(
    "/quadras/{quadra_id}",
    response_model=Quadra,
    responses={404: {"model": ErrorResponse}},
    tags=["quadras"],
)
def get_quadra(quadra_id: str, _=Depends(current_agent)):
    q = _quadra_or_404(quadra_id)
    return {**q, **_resumo(q)}


@app.post(
    "/quadras/{quadra_id}/lotes/{lote_id}/visita",
    response_model=Lote,
    responses={
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        422: {"model": ErrorResponse},
    },
    tags=["quadras"],
)
def registrar_visita(
    quadra_id: str, lote_id: str, body: VisitaRequest, user=Depends(current_agent)
):
    if user["perfil"] != "agente":
        raise ApiError(403, "forbidden", "Só o agente de campo registra visitas.")
    q = _quadra_or_404(quadra_id)
    lote = next(
        (lt for c in q["conjuntos"] for lt in c["lotes"] if lt["id"] == lote_id), None
    )
    if lote is None:
        raise ApiError(404, "lote_not_found", "Lote não encontrado.")
    _apply_visit(
        lote, body.resultado, datetime.now().strftime("%H:%M"), user["nome"],
        body.criadouros, body.larvas, body.animais, body.focos,
    )
    return lote


# --------------------------------------------------------------------- dev


@app.post("/dev/reset", status_code=204, tags=["infra"])
def reset():
    """Restaura os dados iniciais (útil entre testes)."""
    VISITS.clear()
    VISITS.update(_seed_visits())
    QUADRAS.clear()
    QUADRAS.update(_seed_quadras())
    SESSIONS.clear()
    return Response(status_code=204)
