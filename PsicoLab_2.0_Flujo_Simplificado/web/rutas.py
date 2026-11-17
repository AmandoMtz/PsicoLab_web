"""Rutas HTTP de la API."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from . import servicio
from .esquemas import Catalogo, Resultado, Salud, SolicitudResultado

router = APIRouter(prefix='/api')


@router.get('/catalogo', response_model=Catalogo)
def obtener_catalogo():
    return servicio.catalogo()


@router.post('/resultado', response_model=Resultado)
def crear_resultado(solicitud: SolicitudResultado):
    return servicio.calcular_resultado(solicitud)


@router.delete('/registros/{registro_id}', status_code=status.HTTP_204_NO_CONTENT)
def borrar_registro(registro_id: UUID):
    try:
        eliminado = servicio.eliminar_registro(registro_id)
    except (ValueError, RuntimeError) as error:
        raise HTTPException(status_code=503, detail=str(error)) from None
    if not eliminado:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE,
                            'El almacenamiento no está disponible en el servidor.')


@router.get('/salud', response_model=Salud)
def obtener_salud():
    return servicio.salud()
