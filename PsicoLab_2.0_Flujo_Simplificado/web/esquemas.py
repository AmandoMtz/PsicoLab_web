"""Formato de los datos que entran y salen de la API.

Las respuestas solo incluyen lo que muestra la app de escritorio:
la confianza y el umbral de la IA nunca se envían al navegador.
"""
from __future__ import annotations

from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

from psicolab_core import careers


class Pregunta(BaseModel):
    id: int
    pregunta: str
    A: str
    B: str


class Catalogo(BaseModel):
    preguntas: list[Pregunta]
    carreras: list[str]


class SolicitudResultado(BaseModel):
    consentimiento: Literal[True]
    edad: int = Field(ge=17, le=65)
    sexo: Literal['Masculino', 'Femenino']
    carrera: str
    respuestas: list[Literal['A', 'B']] = Field(min_length=20, max_length=20)
    registro_id: UUID | None = None

    @field_validator('carrera')
    @classmethod
    def carrera_disponible(cls, valor: str) -> str:
        if valor not in careers():
            raise ValueError('Selecciona una de las carreras disponibles.')
        return valor


class AreaTrabajo(BaseModel):
    area: str
    actividades: str


class Registro(BaseModel):
    guardado: bool
    id: UUID | None
    mensaje: str


class Resultado(BaseModel):
    clase: int
    perfil: str
    tarjeta: str
    carrera: str
    areas: list[AreaTrabajo]
    registro: Registro


class Salud(BaseModel):
    estado: Literal['ok']
    almacenamiento: str
    guardar_desde: str | None
    guardar_hasta: str | None
