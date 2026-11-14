"""PsicoLab: clasificación SOLO mediante red MLP y orientación ilustrativa.

El nivel de confianza es max(softmax), NO probabilidad psicológica calibrada.
"""
from __future__ import annotations
import json
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

ROOT=Path(__file__).resolve().parent
DATA=ROOT/'datos'
MODEL=ROOT/'modelos'/'MLP_12000.joblib'
CONFIDENCE_THRESHOLDS=(0.60,0.70,0.80,0.90,0.95)

@dataclass(frozen=True)
class Result:
    number: int
    profile: str
    confidence: float
    threshold: float
    accepted: bool
    answers: tuple[str,...]
    alternatives: tuple[tuple[int,str,float],...]
    model_version: str

def questions():
    return json.loads((DATA/'preguntas_20.json').read_text(encoding='utf-8'))

def profiles():
    return {int(k):v for k,v in json.loads((DATA/'perfiles_1_16.json').read_text(encoding='utf-8')).items()}

def careers():
    return list(json.loads((DATA/'areas_profesionales.json').read_text(encoding='utf-8')))

def career_areas(profile,career):
    catalog=json.loads((DATA/'areas_profesionales.json').read_text(encoding='utf-8'))
    if career not in catalog:raise ValueError('Selecciona una de las carreras disponibles.')
    if profile not in profiles().values():raise ValueError('Perfil desconocido.')
    items=[]
    for idx,a in enumerate(catalog[career]):
        n=sum(x==y for x,y in zip(a['preferencias_ilustrativas'],profile))
        items.append((n,idx,a))
    items.sort(key=lambda t:(-t[0],t[1]))
    return [dict(area=x['titulo'],actividades=x['actividades'],matches=n) for n,_,x in items[:3]]

@lru_cache(maxsize=4)
def _model_payload(path: str):
    # joblib/pickle solamente de artefactos confiables generados por PsicoLab.
    import joblib
    payload=joblib.load(path)
    features=[f'R{i:02d}' for i in range(1,21)]
    if payload.get('features')!=features:
        raise ValueError('El modelo cargado no corresponde a los 20 reactivos R01–R20.')
    if list(payload.get('classes',[]))!=list(range(1,17)):
        raise ValueError('El modelo no contiene las 16 etiquetas consecutivas 1–16.')
    estimator=payload['model']
    if list(estimator.classes_)!=list(range(1,17)):
        raise ValueError('Incompatibilidad entre estimador y mapa de clases 1–16.')
    return payload

def active_model_path():
    """En 2.0, el modelo aprobado por el investigador prevalece.
    En 1.0, siempre se usa el modelo distribuido de 12 mil simulaciones.
    """
    from version import ALLOW_REAL_STORAGE
    if ALLOW_REAL_STORAGE:
        from storage import storage_root
        approved=storage_root()/'modelos'/'activo.joblib'
        if approved.is_file():return approved
    return MODEL

def predict_ai(answers,threshold:float=.80,model_path=None)->Result:
    import numpy as np
    vals=tuple(answers)
    if len(vals)!=20 or any(a not in ('A','B') for a in vals):
        raise ValueError('Completa los 20 reactivos A/B para generar la predicción.')
    if not 0<float(threshold)<=1:
        raise ValueError('El umbral de confianza debe estar entre 0 y 100 %.')
    selected=Path(model_path) if model_path else active_model_path()
    payload=_model_payload(str(selected.resolve()))
    X=np.asarray([[0.0 if a=='A' else 1.0 for a in vals]],dtype=np.float32)
    scores=payload['model'].predict_proba(X)[0]
    classes=payload['model'].classes_
    ranking=np.argsort(scores)[::-1]
    idx=int(ranking[0]);number=int(classes[idx]);code=profiles()[number]
    alternatives=tuple((int(classes[int(j)]),profiles()[int(classes[int(j)])],float(scores[int(j)])) for j in ranking[1:4])
    return Result(number,code,float(scores[idx]),float(threshold),bool(scores[idx]>=float(threshold)),
                  vals,alternatives,str(payload.get('version','modelo_sin_version')))

def classify_mlp(answers,model_path=None):
    return predict_ai(answers,model_path=model_path).number

def validation_report():
    return json.loads((DATA/'validacion_5_folds.json').read_text(encoding='utf-8'))

def validate_12000(csv_path=None):
    """Audita estructura y consistencia del archivo; NO aplica la antigua clave.
    Es un dataset sintético previamente etiquetado, no referencia psicológica externa.
    """
    import csv
    p=Path(csv_path) if csv_path else DATA/'entrenamiento_12000_sinteticos.csv'
    seen=set();count=0;class_counts={i:0 for i in range(1,17)}
    with p.open(newline='',encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            raw=tuple(int(row[f'R{i:02d}']) for i in range(1,21))
            if any(v not in (0,1) for v in raw):raise ValueError('Respuesta no binaria')
            label=int(row['Tipo_personalidad'])
            if label not in class_counts:raise ValueError('Clase fuera de 1..16')
            class_counts[label]+=1
            seen.add(raw);count+=1
    return {'registros':count,'patrones_unicos':len(seen),'clases':class_counts,
            'advertencia':'Etiquetas provistas en dataset sintético; la aplicación NO calcula etiquetas por reglas.'}
