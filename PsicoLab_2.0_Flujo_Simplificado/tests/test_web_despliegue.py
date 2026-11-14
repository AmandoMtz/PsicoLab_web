"""Regresiones para la publicación web y reintentos de red."""
from uuid import uuid4
from fastapi.testclient import TestClient
from web.app import app
import storage


def test_reintento_con_id_conserva_un_registro(monkeypatch, tmp_path):
    monkeypatch.setenv('PSICOLAB_DATA_DIR', str(tmp_path))
    monkeypatch.delenv('PSICOLAB_GUARDAR_DESDE', raising=False)
    monkeypatch.delenv('PSICOLAB_GUARDAR_HASTA', raising=False)
    datos = dict(consentimiento=True, edad=20, sexo='Femenino', carrera='Derecho',
                 respuestas=['A'] * 20, registro_id=str(uuid4()))
    with TestClient(app) as c:
        for _ in range(2):
            respuesta = c.post('/api/resultado', json=datos)
            assert respuesta.status_code == 200
            assert respuesta.json()['registro']['id'] == datos['registro_id']
            assert respuesta.headers['cache-control'] == 'no-store'
    assert len(storage.records()) == 1


def test_compresion_y_cache_de_estaticos():
    with TestClient(app) as c:
        pagina = c.get('/css/estilos.css', headers={'Accept-Encoding': 'gzip'})
        assert pagina.status_code == 200
        assert pagina.headers['content-encoding'] == 'gzip'
        assert pagina.headers['cache-control'] == 'no-cache'
        tarjeta = c.get('/tarjetas/INTJ.png')
        assert tarjeta.headers['cache-control'] == 'public, max-age=86400'
        assert tarjeta.headers['x-content-type-options'] == 'nosniff'
        assert tarjeta.headers['x-frame-options'] == 'DENY'


def test_base_y_codigo_no_son_publicos():
    with TestClient(app) as c:
        for ruta in ['/respuestas.sqlite3', '/storage.py', '/datos/entrenamiento_12000_sinteticos.csv', '/.env']:
            assert c.get(ruta).status_code == 404
