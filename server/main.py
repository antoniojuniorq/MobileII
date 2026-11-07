"""MockServer do ACE CONTROL (FastAPI, dados em memória).

Rodar:  uvicorn main:app --reload --host 0.0.0.0 --port 8000
Docs interativas (Swagger): http://localhost:8000/docs
Login de teste: matricula "123456" / senha "ace123"
"""
from __future__ import annotations

import secrets
from datetime import date, datetime, timedelta, timezone
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


class LoginRequest(BaseModel):
    matricula: str = Field(min_length=1, examples=["123456"])
    senha: str = Field(min_length=1, examples=["ace123"])


class Agent(BaseModel):
    id: int
    nome: str
    matricula: str
    municipio: str
    area: str


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
}
PASSWORD = "ace123"
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
SESSIONS: dict[str, datetime] = {}  # auth_code -> expiração
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
    exp = SESSIONS.get(code)
    if exp is None or exp < datetime.now(timezone.utc):
        SESSIONS.pop(code, None)
        raise expired
    return AGENT


@app.get("/health", tags=["infra"])
def health():
    return {"status": "ok"}


@app.post(
    "/auth/login",
    response_model=LoginResponse,
    responses={401: {"model": ErrorResponse}, 422: {"model": ErrorResponse}},
    tags=["auth"],
)
def login(body: LoginRequest):
    if body.matricula != AGENT["matricula"] or body.senha != PASSWORD:
        raise ApiError(401, "invalid_credentials", "Matrícula ou senha incorreta.")
    code = secrets.token_urlsafe(24)
    expires = datetime.now(timezone.utc) + timedelta(hours=SESSION_HOURS)
    SESSIONS[code] = expires
    return {"auth_code": code, "expires_at": expires, "agent": AGENT}


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


# --------------------------------------------------------------------- dev


@app.post("/dev/reset", status_code=204, tags=["infra"])
def reset():
    """Restaura os dados iniciais (útil entre testes)."""
    VISITS.clear()
    VISITS.update(_seed_visits())
    SESSIONS.clear()
    return Response(status_code=204)
