"""Validación de datos capturados, migración no destructiva y persistencia local."""
import json
import sqlite3
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from storage import save,records,remove,database_path
from psicolab_core import questions,predict_ai


def test_demographics_and_migration(tmp_path,monkeypatch):
    monkeypatch.setenv('PSICOLAB_DATA_DIR',str(tmp_path))
    # Base anterior de 2.0, sin edad ni sexo: debe seguir siendo legible.
    db=database_path();db.parent.mkdir(parents=True,exist_ok=True)
    with sqlite3.connect(db) as con:
        con.execute('CREATE TABLE respuestas (id TEXT PRIMARY KEY, fecha TEXT NOT NULL, carrera TEXT NOT NULL, respuestas TEXT NOT NULL, perfil_id INTEGER NOT NULL, perfil TEXT NOT NULL, origen TEXT NOT NULL CHECK(origen="real"))')
    ans=['A']*20
    profile=predict_ai(ans)
    ident=save(ans,'Derecho',profile.number,profile.profile,age=23,sex='Femenino')
    rows=records()
    assert len(rows)==1 and rows[0]['edad']==23 and rows[0]['sexo']=='Femenino'
    assert rows[0]['respuestas']==ans and rows[0]['perfil']==profile.profile
    changed=save(ans,'Turismo',profile.number,profile.profile,ident,age=65,sex='Masculino')
    assert changed==ident
    assert len(records())==1 and records()[0]['edad']==65
    remove(ident)
    assert records()==[]


def test_invalid_demographics(tmp_path,monkeypatch):
    monkeypatch.setenv('PSICOLAB_DATA_DIR',str(tmp_path))
    ans=['A']*20
    p=predict_ai(ans)
    for age in (16,66,'20',None):
        if age is None:continue # los legados pueden contener NULL
        try: save(ans,'Derecho',p.number,p.profile,age=age,sex='Femenino')
        except ValueError: pass
        else: raise AssertionError(f'Se aceptó edad inválida: {age}')
    for sex in ('Otro','', 'femenino'):
        try:save(ans,'Derecho',p.number,p.profile,age=20,sex=sex)
        except ValueError:pass
        else:raise AssertionError('Sexo inválido aceptado')
