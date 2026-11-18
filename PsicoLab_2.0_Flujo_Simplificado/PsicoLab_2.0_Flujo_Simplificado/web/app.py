"""Punto de entrada del servidor: uvicorn web.app:app"""
from __future__ import annotations

import mimetypes
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from starlette.middleware.gzip import GZipMiddleware

from psicolab_core import ROOT
from version import VERSION

from . import servicio
from .config import leer_ventana
from .rutas import router
from .retos import router as retos_router

ESTATICO = Path(__file__).resolve().parent / 'estatico'

# Python toma los tipos de archivo del sistema; en Windows salen del registro y
# varían entre equipos (a veces .js llega como text/plain y el navegador no lo
# ejecuta). Se fijan para que el servidor responda igual en cualquier equipo.
mimetypes.add_type('text/javascript', '.js')
mimetypes.add_type('text/css', '.css')
mimetypes.add_type('font/woff2', '.woff2')


@asynccontextmanager
async def ciclo_de_vida(_app: FastAPI):
    leer_ventana()  # detiene el arranque si las fechas están mal escritas
    servicio.precargar_modelo()
    yield


def crear_app() -> FastAPI:
    app = FastAPI(title=f'PsicoLab {VERSION}', lifespan=ciclo_de_vida)
    app.add_middleware(GZipMiddleware, minimum_size=1000, compresslevel=5)

    @app.middleware('http')
    async def cabeceras(request, call_next):
        response = await call_next(request)
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['Referrer-Policy'] = 'no-referrer'
        response.headers['X-Frame-Options'] = 'DENY'
        if request.url.path.startswith('/api/'):
            response.headers['Cache-Control'] = 'no-store'
        elif request.url.path.startswith(('/tarjetas/', '/fuentes/')):
            response.headers['Cache-Control'] = 'public, max-age=86400'
        else:
            response.headers['Cache-Control'] = 'no-cache'
        return response

    app.include_router(router)
    app.include_router(retos_router)
    app.mount('/tarjetas', StaticFiles(directory=ROOT / 'assets'), name='tarjetas')
    # Va al final: las pantallas web atienden todo lo que no sea /api, /docs o /tarjetas.
    app.mount('/', StaticFiles(directory=ESTATICO, html=True), name='pantallas')
    return app


app = crear_app()
