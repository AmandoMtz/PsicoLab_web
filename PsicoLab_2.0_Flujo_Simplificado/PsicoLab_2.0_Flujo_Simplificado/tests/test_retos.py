"""Flujo B3 con transporte Supabase simulado; no toca registros reales."""
import copy
from urllib.parse import parse_qs
from uuid import uuid4
import pytest
from fastapi.testclient import TestClient
from web.app import app
from web import supabase_storage as db
from prediccion_retos_b3 import predecir_b3

class SupabaseMemoria:
    def __init__(self):
        self.tablas = {'respuestas': {}, 'retos': {}}
    def __call__(self, method, query='', payload=None, prefer=None, *, tabla='respuestas'):
        q=parse_qs(query.lstrip('?'))
        table=self.tablas[tabla]
        rows=list(table.values())
        for field,values in q.items():
            value=values[0]
            if value.startswith('eq.'):
                rows=[r for r in rows if str(r.get(field)) == value[3:]]
            elif value == 'is.null': rows=[r for r in rows if r.get(field) is None]
        if method=='GET': return copy.deepcopy(rows[:int(q.get('limit',[len(rows)])[0])])
        if method=='POST':
            row=copy.deepcopy(payload)
            if tabla=='retos':
                if any(r['registro_id']==row['registro_id'] and r['huella']==row['huella'] for r in table.values()): return None
                row.update(decisiones=None,coincidencias=None)
            table.setdefault(row['id'],{}).update(row)
            return [{'id':row['id']}] if prefer and 'return=representation' in prefer else None
        if method=='PATCH':
            for row in rows: row.update(copy.deepcopy(payload))
            return None
        if method=='DELETE':
            for row in rows:
                table.pop(row['id'])
                if tabla=='respuestas':
                    self.tablas['retos']={k:v for k,v in self.tablas['retos'].items() if v['registro_id']!=row['id']}
            return None
        raise AssertionError(method)

@pytest.fixture
def flujo(monkeypatch):
    monkeypatch.setenv('SUPABASE_URL','https://example.supabase.co')
    monkeypatch.setenv('SUPABASE_SECRET_KEY','sb_secret_testing_only_123456')
    monkeypatch.delenv('PSICOLAB_GUARDAR_DESDE',raising=False)
    monkeypatch.delenv('PSICOLAB_GUARDAR_HASTA',raising=False)
    memory=SupabaseMemoria()
    monkeypatch.setattr(db,'_request',memory)
    with TestClient(app) as client:
        datos=dict(consentimiento=True,edad=20,sexo='Femenino',carrera='Derecho',respuestas=['A']*20,registro_id=str(uuid4()))
        assert client.post('/api/resultado',json=datos).json()['registro']['guardado']
        yield client,memory,datos

def start(c,d):
    return c.post('/api/retos/iniciar',json={'registro_id':d['registro_id']})

def test_predicciones_anteriores_ocultas_y_resultado_idempotente(flujo):
    c,dbase,d=flujo
    first=start(c,d).json()
    assert set(first)=={'reto_id','retos','completado'}
    assert len(first['retos'])==3 and not first['completado']
    row=dbase.tablas['retos'][first['reto_id']]
    assert row['pred_b3']==list(predecir_b3(d['respuestas'],d['edad'],d['sexo'],d['carrera']))
    assert row['decisiones'] is None
    assert start(c,d).json()['reto_id']==first['reto_id']
    payload={'reto_id':first['reto_id'],'decisiones':['A','B','C']}
    r=c.post('/api/retos/finalizar',json=payload)
    assert r.status_code==200 and r.json()['guardado']
    assert r.json()['total']==sum(a==b for a,b in zip(row['pred_b3'],payload['decisiones']))
    assert c.post('/api/retos/finalizar',json=payload).json()==r.json()
    assert start(c,d).json()['resultado']==r.json()
    assert c.post('/api/retos/finalizar',json={**payload,'decisiones':['C']*3}).status_code==409

def test_cambios_al_cuestionario_crean_otra_version(flujo):
    c,dbase,d=flujo
    one=start(c,d).json()['reto_id']
    d['respuestas']=['B']*20
    c.post('/api/resultado',json=d)
    two=start(c,d).json()['reto_id']
    assert one!=two and len(dbase.tablas['retos'])==2
    assert dbase.tablas['retos'][one]['entradas']['respuestas']==['A']*20
    assert dbase.tablas['retos'][two]['entradas']['respuestas']==['B']*20

@pytest.mark.parametrize('choices',[[],['A'],['A','B'],['A','B','Z'],['A','B','C','A']])
def test_rechaza_decisiones_incompletas_o_invalidas(flujo,choices):
    c,dbase,d=flujo
    ident=start(c,d).json()['reto_id']
    assert c.post('/api/retos/finalizar',json={'reto_id':ident,'decisiones':choices}).status_code==422
    assert dbase.tablas['retos'][ident]['decisiones'] is None

def test_no_permite_predicciones_del_cliente(flujo):
    c,_,d=flujo
    assert c.post('/api/retos/iniciar',json={'registro_id':d['registro_id'],'pred_b3':['A']*3}).status_code==422

def test_registro_inexistente_y_borrado(flujo):
    c,dbase,d=flujo
    assert start(c,{'registro_id':str(uuid4())}).status_code==404
    ident=start(c,d).json()['reto_id']
    assert c.delete('/api/registros/'+d['registro_id']).status_code==204
    assert c.post('/api/retos/finalizar',json={'reto_id':ident,'decisiones':['A']*3}).status_code==404

def test_fuera_de_horario_no_inicia(flujo,monkeypatch):
    c,_,d=flujo
    monkeypatch.setenv('PSICOLAB_GUARDAR_DESDE','2100-01-01T00:00')
    assert start(c,d).status_code==409

def test_error_remoto_no_confirma(flujo,monkeypatch):
    c,_,d=flujo
    def fallo(*a,**k): raise RuntimeError('Supabase HTTP 404. Revisa la tabla.')
    monkeypatch.setattr(db,'_request',fallo)
    assert start(c,d).status_code==503


def test_salud_retos(flujo):
    c,_,_=flujo
    response=c.get('/api/retos/salud')
    assert response.status_code==200
    assert response.json()=={'estado':'listo','modelo':'B3','retos':3}
