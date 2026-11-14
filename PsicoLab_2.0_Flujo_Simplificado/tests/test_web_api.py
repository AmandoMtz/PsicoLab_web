"""Rutas de la API web: catálogo, resultado, registro y salud."""
from pathlib import Path
from uuid import UUID
import sys

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from psicolab_core import careers, profiles, questions
from storage import database_path, records
from web.app import app

PERFIL = 'ISFJ'


def respuestas_de(perfil):
    return ['A' if q['pole_A'] == perfil[(q['id'] - 1) // 5] else 'B' for q in questions()]


def solicitud(**cambios):
    datos = dict(consentimiento=True, edad=20, sexo='Femenino', carrera='Derecho',
                 respuestas=respuestas_de(PERFIL))
    datos.update(cambios)
    return datos


@pytest.fixture
def cliente(monkeypatch, tmp_path):
    monkeypatch.setenv('PSICOLAB_DATA_DIR', str(tmp_path))
    monkeypatch.delenv('PSICOLAB_GUARDAR_DESDE', raising=False)
    monkeypatch.delenv('PSICOLAB_GUARDAR_HASTA', raising=False)
    with TestClient(app) as c:
        yield c


def test_catalogo_sin_claves_de_puntuacion(cliente):
    datos = cliente.get('/api/catalogo').json()
    assert len(datos['preguntas']) == 20
    assert all(set(p) == {'id', 'pregunta', 'A', 'B'} for p in datos['preguntas'])
    assert datos['carreras'] == careers()


def test_resultado_guarda_y_no_expone_confianza(cliente):
    r = cliente.post('/api/resultado', json=solicitud())
    assert r.status_code == 200
    datos = r.json()
    assert set(datos) == {'clase', 'perfil', 'tarjeta', 'carrera', 'areas', 'registro'}
    assert datos['perfil'] == PERFIL and profiles()[datos['clase']] == PERFIL
    assert len(datos['areas']) == 3
    assert 'confi' not in r.text and 'umbral' not in r.text
    assert datos['registro']['guardado'] is True
    filas = records()
    assert len(filas) == 1 and filas[0]['id'] == datos['registro']['id']
    assert (filas[0]['edad'], filas[0]['sexo'], filas[0]['carrera']) == (20, 'Femenino', 'Derecho')


def test_tarjeta_se_sirve(cliente):
    ruta = cliente.post('/api/resultado', json=solicitud()).json()['tarjeta']
    imagen = cliente.get(ruta)
    assert imagen.status_code == 200 and imagen.headers['content-type'] == 'image/png'


def test_revisar_respuestas_actualiza_el_mismo_registro(cliente):
    primero = cliente.post('/api/resultado', json=solicitud()).json()['registro']['id']
    segundo = cliente.post('/api/resultado',
                           json=solicitud(carrera='Turismo', registro_id=primero)).json()
    assert segundo['registro']['id'] == primero
    assert len(records()) == 1 and records()[0]['carrera'] == 'Turismo'


def test_eliminar_registro(cliente):
    ident = cliente.post('/api/resultado', json=solicitud()).json()['registro']['id']
    assert cliente.delete(f'/api/registros/{ident}').status_code == 204
    assert records() == []


@pytest.mark.parametrize('variable,valor,texto', [
    ('PSICOLAB_GUARDAR_DESDE', '2100-01-01T00:00', 'Modo de prueba'),
    ('PSICOLAB_GUARDAR_HASTA', '2000-01-01T00:00', 'terminó'),
])
def test_fuera_de_la_ventana_no_guarda(cliente, monkeypatch, variable, valor, texto):
    monkeypatch.setenv(variable, valor)
    datos = cliente.post('/api/resultado', json=solicitud()).json()
    assert datos['perfil'] == PERFIL
    assert datos['registro'] == {'guardado': False, 'id': None,
                                 'mensaje': datos['registro']['mensaje']}
    assert texto in datos['registro']['mensaje']
    assert not database_path().exists()


def test_sin_disco_no_guarda_ni_elimina(cliente, monkeypatch, tmp_path):
    monkeypatch.setenv('PSICOLAB_DATA_DIR', str(tmp_path / 'disco_no_montado'))
    datos = cliente.post('/api/resultado', json=solicitud()).json()
    assert datos['registro']['guardado'] is False
    respuesta = cliente.delete(f'/api/registros/{UUID(int=1)}')
    assert respuesta.status_code == 503
    assert not (tmp_path / 'disco_no_montado').exists()


@pytest.mark.parametrize('cambios', [
    dict(consentimiento=False),
    dict(edad=16),
    dict(edad=66),
    dict(sexo='Otro'),
    dict(carrera='Medicina'),
    dict(respuestas=['A'] * 19),
    dict(respuestas=['A'] * 19 + ['C']),
    dict(registro_id='no-es-un-uuid'),
])
def test_datos_invalidos_se_rechazan(cliente, cambios):
    assert cliente.post('/api/resultado', json=solicitud(**cambios)).status_code == 422
    assert not database_path().exists()


def test_salud(cliente, monkeypatch, tmp_path):
    datos = cliente.get('/api/salud').json()
    assert datos == {'estado': 'ok', 'almacenamiento': 'listo',
                     'guardar_desde': None, 'guardar_hasta': None}
    monkeypatch.setenv('PSICOLAB_GUARDAR_DESDE', '2026-11-19T00:00')
    monkeypatch.setenv('PSICOLAB_DATA_DIR', str(tmp_path / 'sin_disco'))
    datos = cliente.get('/api/salud').json()
    assert datos['guardar_desde'] == '19/11/2026 00:00'
    assert datos['almacenamiento'] == 'no configurado'


def test_fecha_mal_escrita_impide_arrancar(monkeypatch):
    monkeypatch.setenv('PSICOLAB_GUARDAR_DESDE', '19/11/2026')
    with pytest.raises(ValueError, match='AAAA-MM-DDTHH:MM'):
        with TestClient(app):
            pass
