import json
from io import BytesIO
from uuid import UUID
from urllib.error import HTTPError, URLError
import pytest
from web import supabase_storage as sb
from web.config import estado_registro
from web import servicio

@pytest.fixture(autouse=True)
def config(monkeypatch):
    monkeypatch.setenv('SUPABASE_URL', 'https://example.supabase.co')
    monkeypatch.setenv('SUPABASE_SECRET_KEY', 'sb_secret_testing_only_123456')
    monkeypatch.delenv('PSICOLAB_DATA_DIR', raising=False)
    monkeypatch.delenv('PSICOLAB_GUARDAR_DESDE', raising=False)
    monkeypatch.delenv('PSICOLAB_GUARDAR_HASTA', raising=False)


def test_crear_actualizar_eliminar(monkeypatch):
    calls=[]
    def req(method, query='', payload=None, prefer=None):
        calls.append((method, query, payload, prefer))
        return [{'id': payload['id']}] if payload else None
    monkeypatch.setattr(sb, '_request', req)
    from psicolab_core import profiles, careers
    pid, profile = next(iter(profiles().items()))
    ident=sb.save(['A']*20, careers()[0], pid, profile, age=20, sex='Femenino')
    UUID(ident)
    assert sb.save(['B']*20, careers()[0], pid, profile, ident, age=20, sex='Femenino') == ident
    assert calls[1][2]['respuestas'] == ['B']*20
    assert 'fecha' not in calls[1][2]
    assert 'on_conflict=id' in calls[1][1]
    sb.remove(ident)
    assert calls[-1][:2] == ('DELETE', '?id=eq.'+ident)


def test_api_key_header_y_https(monkeypatch):
    seen=[]
    class Opener:
        def open(self, req, timeout):
            seen.append(req)
            return BytesIO(b'[]')
    monkeypatch.setattr(sb, 'build_opener', lambda *args: Opener())
    sb.comprobar()
    assert seen[0].get_header('Apikey').startswith('sb_secret_')
    assert seen[0].get_header('Authorization') is None
    monkeypatch.setenv('SUPABASE_URL', 'http://example.supabase.co')
    with pytest.raises(ValueError): sb.comprobar()


def test_no_fallback_y_fechas(monkeypatch):
    assert estado_registro().activo
    monkeypatch.setenv('PSICOLAB_GUARDAR_DESDE', '2100-01-01T00:00')
    assert not estado_registro().activo
    monkeypatch.delenv('PSICOLAB_GUARDAR_DESDE')
    monkeypatch.delenv('SUPABASE_SECRET_KEY')
    assert sb.seleccionado()
    assert not estado_registro().activo
    assert servicio._estado_almacenamiento().startswith('error:')

@pytest.mark.parametrize('failure', [HTTPError('https://example.supabase.co',403,'secret',{},BytesIO(b'private data')), URLError('secret')])
def test_errores_no_exponen_datos(monkeypatch, failure):
    class Opener:
        def open(self,*a,**k): raise failure
    monkeypatch.setattr(sb,'build_opener',lambda *args: Opener())
    with pytest.raises(RuntimeError) as e: sb.comprobar()
    assert 'secret' not in str(e.value) and 'private data' not in str(e.value)


def test_guardado_requiere_confirmacion(monkeypatch):
    monkeypatch.setattr(sb,'_request',lambda *a,**k: [])
    from psicolab_core import profiles, careers
    pid, profile=next(iter(profiles().items()))
    with pytest.raises(RuntimeError):
        sb.save(['A']*20,careers()[0],pid,profile,age=20,sex='Femenino')


def test_ruta_completa_supabase(monkeypatch):
    from fastapi.testclient import TestClient
    from web.app import app
    captured=[]
    def req(method,query='',payload=None,prefer=None):
        captured.append((method,payload))
        return [{'id':payload['id']}] if payload else []
    monkeypatch.setattr(sb,'_request',req)
    with TestClient(app) as client:
        assert client.get('/api/salud').json()['almacenamiento']=='listo (Supabase)'
        result=client.post('/api/resultado',json=dict(consentimiento=True,edad=20,sexo='Femenino',carrera='Derecho',respuestas=['A']*20)).json()
        assert result['registro']['guardado'] is True
        assert captured[-1][1]['edad']==20
        assert client.delete('/api/registros/'+result['registro']['id']).status_code==204
        monkeypatch.setattr(sb,'_request',lambda *a,**k: (_ for _ in ()).throw(RuntimeError('Supabase no disponible')))
        result=client.post('/api/resultado',json=dict(consentimiento=True,edad=20,sexo='Femenino',carrera='Derecho',respuestas=['A']*20)).json()
        assert result['registro']['guardado'] is False
        assert result['registro']['id'] is None
