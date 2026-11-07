# MockServer — ACE CONTROL

API simulada em **FastAPI** (dados em memória) usada pelo app durante o desenvolvimento.
Contrato completo em [`../docs/API.md`](../docs/API.md).

## Rodar

```powershell
cd server
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

(ou, na raiz do repositório: `scripts\run_server.ps1`)

- Swagger interativo: http://localhost:8000/docs
- Login de teste: matrícula `123456`, senha `ace123`
- Restaurar os dados iniciais: `POST /dev/reset`

## Testar

```powershell
python -m pytest -q
```

## Observações

- `--host 0.0.0.0` permite que o emulador (`10.0.2.2:8000`) e o celular na mesma rede enxerguem o servidor.
- Os dados voltam ao estado inicial sempre que o servidor reinicia.
- O horário gravado ao registrar uma visita é o horário do computador onde o servidor roda.
