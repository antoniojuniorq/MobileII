import pytest
from fastapi.testclient import TestClient

from main import app

client = TestClient(app)
CREDS = {"matricula": "123456", "senha": "ace123"}


@pytest.fixture(autouse=True)
def _reset():
    client.post("/dev/reset")


def _auth() -> dict:
    code = client.post("/auth/login", json=CREDS).json()["auth_code"]
    return {"Authorization": f"Bearer {code}"}


def test_login_ok():
    r = client.post("/auth/login", json=CREDS)
    assert r.status_code == 200
    body = r.json()
    assert body["auth_code"] and body["agent"]["nome"] == "Antonio Junior"


def test_login_credenciais_erradas():
    r = client.post("/auth/login", json={"matricula": "123456", "senha": "x"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "invalid_credentials"


def test_login_campos_ausentes():
    r = client.post("/auth/login", json={"matricula": "123456"})
    assert r.status_code == 422
    err = r.json()["error"]
    assert err["code"] == "validation_error"
    assert err["fields"][0]["field"] == "senha"


def test_rotas_exigem_auth():
    for path in ["/me", "/summary/today", "/visits"]:
        r = client.get(path)
        assert r.status_code == 401
        assert r.json()["error"]["code"] == "unauthorized"


def test_me():
    assert client.get("/me", headers=_auth()).json()["matricula"] == "123456"


def test_resumo_e_lista():
    h = _auth()
    s = client.get("/summary/today", headers=h).json()
    assert (s["visits_total"], s["visits_done"], s["visits_pending"]) == (10, 6, 4)
    assert s["focos_found"] == 1
    assert len(client.get("/visits", headers=h).json()) == 10
    pend = client.get("/visits?status=pendente", headers=h).json()
    assert len(pend) == 4


def test_atualizar_visita_muda_resumo():
    h = _auth()
    r = client.patch("/visits/6", json={"status": "visitado"}, headers=h)
    assert r.status_code == 200
    assert r.json()["status"] == "visitado" and r.json()["horario"]
    assert client.get("/summary/today", headers=h).json()["visits_pending"] == 3


def test_status_invalido():
    r = client.patch("/visits/6", json={"status": "xyz"}, headers=_auth())
    assert r.status_code == 422


def test_visita_inexistente():
    r = client.get("/visits/999", headers=_auth())
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "visit_not_found"


def test_logout_invalida_token():
    h = _auth()
    assert client.post("/auth/logout", headers=h).status_code == 204
    assert client.get("/me", headers=h).status_code == 401
