"""B3: 20 reactivos, edad, sexo, carrera one-hot y 4 puntajes de dimensión.
Las puntuaciones provienen de la clave real pole_A/pole_B de preguntas_20.json.
"""
import json
from functools import lru_cache
from pathlib import Path
import numpy as np

PAIRS=(("E/I","E"),("S/N","S"),("T/F","T"),("J/P","J"))

@lru_cache(maxsize=1)
def _question_key():
    questions=json.loads((Path(__file__).resolve().parent/"datos"/"preguntas_20.json").read_text(encoding="utf-8"))
    assert len(questions)==20
    return questions

def dimension_scores(raw):
    """raw: matriz N x 20 binaria (0=A, 1=B); resultados N x 4 de 0 a 5."""
    raw=np.asarray(raw,dtype=np.int8)
    if raw.ndim!=2 or raw.shape[1]!=20 or not np.isin(raw,[0,1]).all():
        raise ValueError("Se esperan respuestas binarias de 20 reactivos")
    q=_question_key()
    scores=np.zeros((len(raw),4),dtype=np.int8)
    for i, question in enumerate(q):
        for j,(dimension,pole) in enumerate(PAIRS):
            if question["dimension"]==dimension:
                scores[:,j] += np.where(raw[:,i]==0,question["pole_A"]==pole,question["pole_B"]==pole).astype(np.int8)
                break
        else: raise ValueError("Dimensión desconocida en la clave")
    if not np.logical_and(scores>=0,scores<=5).all(): raise ValueError("Puntuación dimensional fuera de rango")
    return scores

def matrix_b3(raw,demographics):
    raw=np.asarray(raw,dtype=np.int8)
    demo=np.asarray(demographics,dtype=int)
    if demo.shape!=(len(raw),3):raise ValueError("Demografía debe contener Edad, Sexo, Carrera")
    if not np.isin(demo[:,2],range(1,7)).all():raise ValueError("Carrera fuera de rango 1..6")
    career=(demo[:,2,None]==np.arange(1,7)).astype(np.float32)
    return np.column_stack((raw,demo[:,0],demo[:,1],career,dimension_scores(raw))).astype(np.float32)

FEATURE_NAMES=([f"R{i:02d}" for i in range(1,21)] +["Edad","Sexo"]+[f"Carrera_{i}" for i in range(1,7)]+["Puntuacion_E","Puntuacion_S","Puntuacion_T","Puntuacion_J"])
assert len(FEATURE_NAMES)==32
