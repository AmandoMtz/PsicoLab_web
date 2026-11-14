"""Casos de uso del servidor; reutilizan el núcleo de PsicoLab sin modificarlo."""
from __future__ import annotations

import logging
from uuid import UUID

import storage
from psicolab_core import career_areas, careers, predict_ai, questions
from version import ALLOW_REAL_STORAGE

from .config import FORMATO_VISIBLE, directorio_datos, estado_registro, leer_ventana
from .esquemas import (AreaTrabajo, Catalogo, Pregunta, Registro, Resultado, Salud,
                       SolicitudResultado)

# Mismo umbral fijo que la app de escritorio; se calcula pero no se muestra.
UMBRAL_OPERACION = 0.80

log = logging.getLogger('psicolab.web')


def precargar_modelo() -> None:
    """Carga la red al arrancar para detectar pronto un modelo o scikit-learn incompatibles."""
    predict_ai(['A'] * 20, threshold=UMBRAL_OPERACION)


def catalogo() -> Catalogo:
    preguntas = [Pregunta(id=q['id'], pregunta=q['question'], A=q['A'], B=q['B'])
                 for q in questions()]
    return Catalogo(preguntas=preguntas, carreras=careers())


def calcular_resultado(solicitud: SolicitudResultado) -> Resultado:
    prediccion = predict_ai(solicitud.respuestas, threshold=UMBRAL_OPERACION)
    areas = career_areas(prediccion.profile, solicitud.carrera)
    return Resultado(
        clase=prediccion.number,
        perfil=prediccion.profile,
        tarjeta=f'/tarjetas/{prediccion.profile}.png',
        carrera=solicitud.carrera,
        areas=[AreaTrabajo(area=a['area'], actividades=a['actividades']) for a in areas],
        registro=_guardar(solicitud, prediccion),
    )


def _guardar(solicitud: SolicitudResultado, prediccion) -> Registro:
    estado = estado_registro()
    if not estado.activo:
        return Registro(guardado=False, id=None, mensaje=estado.mensaje)
    anterior = str(solicitud.registro_id) if solicitud.registro_id else None
    try:
        ident = storage.save(prediccion.answers, solicitud.carrera, prediccion.number,
                             prediccion.profile, anterior, age=solicitud.edad, sex=solicitud.sexo)
    except Exception as error:
        log.exception('No se pudo guardar el registro')
        return Registro(guardado=False, id=None, mensaje=f'No se pudo guardar el registro: {error}')
    return Registro(guardado=True, id=ident, mensaje=estado.mensaje)


def eliminar_registro(ident: UUID) -> bool:
    """Devuelve False si el servidor no tiene almacenamiento disponible."""
    if directorio_datos() is None:
        return False
    storage.remove(str(ident))
    return True


def salud() -> Salud:
    ventana = leer_ventana()
    return Salud(
        estado='ok',
        almacenamiento=_estado_almacenamiento(),
        guardar_desde=ventana.desde.strftime(FORMATO_VISIBLE) if ventana.desde else None,
        guardar_hasta=ventana.hasta.strftime(FORMATO_VISIBLE) if ventana.hasta else None,
    )


def _estado_almacenamiento() -> str:
    if not ALLOW_REAL_STORAGE:
        return 'desactivado'
    if directorio_datos() is None:
        return 'no configurado'
    try:
        storage.model_history()  # abre o crea la base: comprueba permisos de escritura
    except Exception as error:
        log.exception('La base de datos no se pudo abrir')
        return f'error: {error}'
    return 'listo'
