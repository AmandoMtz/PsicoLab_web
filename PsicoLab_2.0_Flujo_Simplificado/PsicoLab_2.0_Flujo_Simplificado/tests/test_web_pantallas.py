"""Archivos de las pantallas web: se sirven bien y el consentimiento coincide con escritorio."""
import ast
import json
from pathlib import Path
import sys

import pytest
from fastapi.testclient import TestClient

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ))
from web.app import ESTATICO, app

TIPOS = {'.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.svg': 'image/svg+xml',
         '.woff2': 'font/woff2', '.txt': 'text/plain'}


@pytest.fixture
def cliente(monkeypatch):
    monkeypatch.delenv('PSICOLAB_GUARDAR_DESDE', raising=False)
    monkeypatch.delenv('PSICOLAB_GUARDAR_HASTA', raising=False)
    with TestClient(app) as c:
        yield c


def test_pagina_principal(cliente):
    r = cliente.get('/')
    assert r.status_code == 200 and r.headers['content-type'].startswith('text/html')
    assert 'PsicoLab 2.0' in r.text and '/js/main.js' in r.text and '/css/estilos.css' in r.text


@pytest.mark.parametrize('archivo', sorted(p.relative_to(ESTATICO).as_posix()
                                           for p in ESTATICO.rglob('*') if p.is_file()))
def test_cada_archivo_se_sirve(cliente, archivo):
    r = cliente.get(f'/{archivo}')
    assert r.status_code == 200
    assert r.headers['content-type'].startswith(TIPOS[Path(archivo).suffix])


def test_la_api_sigue_respondiendo_con_las_pantallas_montadas(cliente):
    assert cliente.get('/api/salud').status_code == 200
    assert cliente.get('/docs').status_code == 200
    assert cliente.get('/api/no-existe').status_code == 404


def test_consentimiento_con_correcciones_editoriales_autorizadas():
    arbol = ast.parse((RAIZ / 'app_psicolab.py').read_text(encoding='utf-8'))
    constantes = {nodo.targets[0].id: ast.literal_eval(nodo.value) for nodo in arbol.body
                  if isinstance(nodo, ast.Assign) and getattr(nodo.targets[0], 'id', '')
                  in ('CONSENT_TITLE', 'CONSENT_TEXT')}
    textos = (ESTATICO / 'js' / 'textos.js').read_text(encoding='utf-8')
    for fragmento in [constantes['CONSENT_TITLE'], *constantes['CONSENT_TEXT'].split('\n\n')]:
        fragmento = (fragmento.replace('Consentimiento informado para participar en PsicoLab', 'Consentimiento de participación')
                     .replace('Estimado(a) estudiante:', 'Estimado(a) participante:')
                     .replace('anonima', 'anónima').replace('anonimo', 'anónimo').replace('  agrupada', ' agrupada'))
        assert json.dumps(fragmento, ensure_ascii=False)[1:-1] in textos, fragmento[:60]
