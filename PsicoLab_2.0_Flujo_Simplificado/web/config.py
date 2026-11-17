"""Cuándo y dónde puede guardar respuestas el servidor web.

Variables de entorno (hora del centro de México, formato AAAA-MM-DDTHH:MM):
  PSICOLAB_GUARDAR_DESDE  primer momento en que se guardan respuestas.
  PSICOLAB_GUARDAR_HASTA  momento en que se deja de guardar.
  PSICOLAB_DATA_DIR       carpeta de la base SQLite; debe existir.
Sin fechas no hay límite de tiempo; sin carpeta existente nunca se guarda.
"""
from __future__ import annotations

import os
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

from version import ALLOW_REAL_STORAGE
from . import supabase_storage

# México eliminó el horario de verano en 2022: el centro del país es UTC-6 todo el año.
ZONA_MEXICO = timezone(timedelta(hours=-6), 'UTC-6')
FORMATO_FECHA = '%Y-%m-%dT%H:%M'
FORMATO_VISIBLE = '%d/%m/%Y %H:%M'


@dataclass(frozen=True)
class VentanaRegistro:
    desde: datetime | None
    hasta: datetime | None


@dataclass(frozen=True)
class EstadoRegistro:
    activo: bool
    mensaje: str


def _leer_fecha(variable: str) -> datetime | None:
    texto = os.getenv(variable, '').strip()
    if not texto:
        return None
    try:
        return datetime.strptime(texto, FORMATO_FECHA).replace(tzinfo=ZONA_MEXICO)
    except ValueError:
        raise ValueError(f'{variable} debe tener el formato AAAA-MM-DDTHH:MM '
                         f'(por ejemplo 2026-11-19T00:00); se recibió {texto!r}.') from None


def leer_ventana() -> VentanaRegistro:
    ventana = VentanaRegistro(_leer_fecha('PSICOLAB_GUARDAR_DESDE'),
                              _leer_fecha('PSICOLAB_GUARDAR_HASTA'))
    if ventana.desde and ventana.hasta and ventana.desde >= ventana.hasta:
        raise ValueError('PSICOLAB_GUARDAR_DESDE debe ser anterior a PSICOLAB_GUARDAR_HASTA.')
    return ventana


def directorio_datos() -> Path | None:
    """Carpeta de datos configurada y existente (en Render, el disco persistente)."""
    ruta = os.getenv('PSICOLAB_DATA_DIR', '').strip()
    if not ruta:
        return None
    carpeta = Path(ruta).expanduser()
    return carpeta if carpeta.is_dir() else None


def estado_registro(ahora: datetime | None = None) -> EstadoRegistro:
    if not ALLOW_REAL_STORAGE:
        return EstadoRegistro(False, 'El almacenamiento está desactivado; esta respuesta no se guardó.')
    ventana = leer_ventana()
    ahora = ahora or datetime.now(ZONA_MEXICO)
    if ventana.desde and ahora < ventana.desde:
        inicio = ventana.desde.strftime(FORMATO_VISIBLE)
        return EstadoRegistro(False, f'Modo de prueba: el registro comienza el {inicio}; '
                                     'esta respuesta no se guardó.')
    if ventana.hasta and ahora >= ventana.hasta:
        return EstadoRegistro(False, 'El periodo de registro terminó; esta respuesta no se guardó.')
    if supabase_storage.seleccionado():
        try:
            supabase_storage.configuracion()
        except ValueError as error:
            return EstadoRegistro(False, str(error))
        return EstadoRegistro(True, 'Registro consentido guardado en Supabase (datos seudonimizados).')
    if directorio_datos() is None:
        return EstadoRegistro(False, 'El almacenamiento no está configurado en el servidor; '
                                     'esta respuesta no se guardó.')
    return EstadoRegistro(True, 'Registro consentido guardado (datos seudonimizados).')
