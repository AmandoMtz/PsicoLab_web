"""Predicción de tres retos con B3. Solo demostración con simulaciones."""
from pathlib import Path
from functools import lru_cache
import joblib
import numpy as np
from psicolab_core import careers
from features_b3 import matrix_b3,FEATURE_NAMES

ROOT=Path(__file__).resolve().parent

@lru_cache(maxsize=3)
def _model(reto):
    if reto not in (1,2,3):raise ValueError("Reto fuera de rango")
    payload=joblib.load(ROOT/'modelos'/f'retos_B3_reto{reto}.joblib')
    if payload.get('mode')!='B3' or payload.get('reto')!=reto or payload.get('feature_names')!=FEATURE_NAMES:
        raise ValueError("Incompatibilidad de esquema de B3")
    return payload['model']

def predecir_b3(respuestas, edad, sexo, carrera):
    if len(respuestas)!=20 or any(v not in ('A','B') for v in respuestas):
        raise ValueError("Completa los 20 reactivos")
    edad=int(edad)
    if not 17<=edad<=65:raise ValueError("Edad fuera de rango")
    if sexo not in ('Femenino','Masculino'):raise ValueError("Sexo no reconocido")
    carreras=careers()
    if carrera not in carreras:raise ValueError("Carrera no reconocida")
    raw=np.asarray([[0 if v=='A' else 1 for v in respuestas]],dtype=np.int8)
    demo=np.asarray([[edad,0 if sexo=='Femenino' else 1,carreras.index(carrera)+1]])
    X=matrix_b3(raw,demo)
    return tuple('ABC'[int(_model(i).predict(X)[0])] for i in (1,2,3))
