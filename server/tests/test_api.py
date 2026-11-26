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


# ---------------------------------------------------------------- perfis

SUP = {"matricula": "654321", "senha": "sup123", "perfil": "supervisor"}


def test_login_supervisor():
    r = client.post("/auth/login", json=SUP)
    assert r.status_code == 200
    assert r.json()["agent"]["perfil"] == "supervisor"


def test_login_perfil_errado():
    r = client.post("/auth/login", json={**CREDS, "perfil": "supervisor"})
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "wrong_profile"


# --------------------------------------------------------------- quadras


def test_quadra_1106():
    h = _auth()
    resumo = client.get("/quadras", headers=h).json()
    assert [q["id"] for q in resumo] == ["1106"]
    q = client.get("/quadras/1106", headers=h).json()
    lotes = [lote for c in q["conjuntos"] for lote in c["lotes"]]
    assert q["total_lotes"] == len(lotes) > 300
    assert len({lote["id"] for lote in lotes}) == len(lotes)
    assert (q["visitados"], q["sem_acesso"]) == (6, 2)


def test_lotes_nao_se_sobrepoem():
    q = client.get("/quadras/1106", headers=_auth()).json()
    rects = [(r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"]) for r in q["conjuntos"] + q["areas"]]
    for i, a in enumerate(rects):
        assert a[2] <= q["largura"] and a[3] <= q["altura"]
        for b in rects[i + 1:]:
            assert a[2] <= b[0] or b[2] <= a[0] or a[3] <= b[1] or b[3] <= a[1], (a, b)


def test_registrar_visita_no_lote():
    h = _auth()
    body = {"resultado": "visitado", "criadouros": 2, "larvas": 15, "animais": 1, "focos": 1}
    r = client.post("/quadras/1106/lotes/AL05-L03/visita", json=body, headers=h)
    assert r.status_code == 200
    lote = r.json()
    assert lote["status"] == "visitado" and lote["visita"]["larvas"] == 15
    assert client.get("/quadras/1106", headers=h).json()["visitados"] == 7


def test_recusa_zera_numeros():
    body = {"resultado": "recusado", "criadouros": 9}
    r = client.post("/quadras/1106/lotes/AL05-L04/visita", json=body, headers=_auth())
    assert r.json()["status"] == "sem_acesso"
    assert r.json()["visita"]["criadouros"] == 0


def test_visita_valida_numeros_e_lote():
    h = _auth()
    bad = client.post("/quadras/1106/lotes/AL05-L03/visita",
                      json={"resultado": "visitado", "larvas": -1}, headers=h)
    assert bad.status_code == 422
    none = client.post("/quadras/1106/lotes/XX/visita", json={"resultado": "visitado"}, headers=h)
    assert none.json()["error"]["code"] == "lote_not_found"


def test_supervisor_nao_registra_visita():
    code = client.post("/auth/login", json=SUP).json()["auth_code"]
    r = client.post("/quadras/1106/lotes/AL05-L03/visita", json={"resultado": "visitado"},
                    headers={"Authorization": f"Bearer {code}"})
    assert r.status_code == 403
