"""Predicciones B3 persistidas antes de responder y reveladas solo al finalizar."""
import hashlib
import json
from datetime import datetime, timezone
from uuid import UUID, uuid4
from typing import Literal
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, ConfigDict
from prediccion_retos_b3 import predecir_b3
from . import supabase_storage as db
from .config import estado_registro
from .retos_catalogo import RETOS

router = APIRouter(prefix='/api/retos', tags=['retos'])

class Inicio(BaseModel):
    model_config = ConfigDict(extra='forbid')
    registro_id: UUID

class Final(BaseModel):
    model_config = ConfigDict(extra='forbid')
    reto_id: UUID
    decisiones: list[Literal['A','B','C']] = Field(min_length=3, max_length=3)


def disponible():
    if not db.seleccionado():
        raise HTTPException(503, 'Los retos requieren la conexión con Supabase.')
    status = estado_registro()
    if not status.activo:
        raise HTTPException(409, status.mensaje)


def consulta(method, query='', payload=None, prefer=None, tabla='retos'):
    try:
        return db._request(method, query, payload, prefer, tabla=tabla)
    except (RuntimeError, ValueError) as error:
        raise HTTPException(503, str(error)) from None


def respuesta_final(row):
    decisiones = row.get('decisiones')
    pred = row.get('pred_b3')
    if not decisiones or not pred:
        raise HTTPException(409, 'Los retos todavía no se han completado.')
    coincidencias = [a == b for a,b in zip(pred, decisiones)]
    return dict(reto_id=row['id'], predicciones=pred, decisiones=decisiones,
                coincidencias=coincidencias, total=sum(coincidencias), guardado=True)


@router.post('/iniciar')
def iniciar(datos: Inicio):
    disponible()
    registros = consulta('GET', '?id=eq.' + str(datos.registro_id)
                         + '&select=id,edad,sexo,carrera,respuestas&limit=1', tabla='respuestas')
    if not registros:
        raise HTTPException(404, 'Primero guarda tu cuestionario para comenzar los retos.')
    source = registros[0]
    huella = hashlib.sha256(json.dumps(source, sort_keys=True, ensure_ascii=False).encode()).hexdigest()
    query = '?registro_id=eq.' + str(datos.registro_id) + '&huella=eq.' + huella + '&limit=1'
    rows = consulta('GET', query)
    if not rows:
        try:
            pred = predecir_b3(source['respuestas'], source['edad'], source['sexo'], source['carrera'])
        except Exception:
            raise HTTPException(503, 'No se pudieron cargar los modelos de retos. Revisa el despliegue.') from None
        row = dict(id=str(uuid4()), registro_id=str(datos.registro_id), huella=huella,
                   entradas=source, pred_b3=list(pred), modelo='B3')
        # Ante doble clic o reintento, conservar las primeras predicciones.
        consulta('POST', '?on_conflict=registro_id,huella', row,
                 'resolution=ignore-duplicates,return=minimal')
        rows = consulta('GET', query)
    if not rows:
        raise HTTPException(503, 'No se confirmó el inicio de los retos. Intenta nuevamente.')
    row = rows[0]
    result = dict(reto_id=row['id'], retos=RETOS, completado=bool(row.get('decisiones')))
    if result['completado']:
        result['resultado'] = respuesta_final(row)
    # No devolver predicciones, probabilidades ni entradas antes de responder.
    return result


@router.post('/finalizar')
def finalizar(datos: Final):
    disponible()
    query = '?id=eq.' + str(datos.reto_id)
    rows = consulta('GET', query + '&limit=1')
    if not rows:
        raise HTTPException(404, 'No se encontró este reto. Vuelve a comenzar desde tu perfil.')
    row = rows[0]
    if not row.get('decisiones'):
        matches = sum(a == b for a,b in zip(row['pred_b3'], datos.decisiones))
        consulta('PATCH', query + '&decisiones=is.null',
                 dict(decisiones=datos.decisiones, coincidencias=matches,
                      finalizado_en=datetime.now(timezone.utc).isoformat()), 'return=minimal')
        rows = consulta('GET', query + '&limit=1')
        if not rows:
            raise HTTPException(404, 'El registro ya no existe.')
        row = rows[0]
    if row.get('decisiones') != datos.decisiones:
        raise HTTPException(409, 'Este reto ya fue finalizado. Vuelve a tu perfil para consultar el resultado.')
    return respuesta_final(row)


@router.get('/salud')
def salud_retos():
    if not db.seleccionado():
        raise HTTPException(503, 'Configura Supabase para habilitar los retos.')
    consulta('GET', '?select=id,huella,pred_b3,decisiones,entradas&limit=0')
    try:
        from prediccion_retos_b3 import _model
        for i in (1, 2, 3):
            _model(i)
    except Exception:
        raise HTTPException(503, 'Faltan modelos B3 o no son compatibles.') from None
    return {'estado': 'listo', 'modelo': 'B3', 'retos': 3}
