"""Ventana de registro del servidor web: cuándo se guardan las respuestas."""
from datetime import datetime, timezone
from pathlib import Path
import sys

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from web.config import ZONA_MEXICO, estado_registro, leer_ventana


def mx(texto):
    return datetime.strptime(texto, '%Y-%m-%d %H:%M').replace(tzinfo=ZONA_MEXICO)


@pytest.fixture
def ventana_19(monkeypatch, tmp_path):
    monkeypatch.setenv('PSICOLAB_DATA_DIR', str(tmp_path))
    monkeypatch.setenv('PSICOLAB_GUARDAR_DESDE', '2026-11-19T00:00')
    monkeypatch.setenv('PSICOLAB_GUARDAR_HASTA', '2026-11-19T18:30')


@pytest.mark.parametrize('momento,activo', [
    ('2026-11-18 19:00', False),
    ('2026-11-18 23:59', False),
    ('2026-11-19 00:00', True),
    ('2026-11-19 12:00', True),
    ('2026-11-19 18:29', True),
    ('2026-11-19 18:30', False),
    ('2026-11-19 19:00', False),
])
def test_ventana_del_19(ventana_19, momento, activo):
    assert estado_registro(mx(momento)).activo is activo


def test_mensajes_antes_y_despues(ventana_19):
    antes = estado_registro(mx('2026-11-18 20:00')).mensaje
    despues = estado_registro(mx('2026-11-19 18:45')).mensaje
    assert antes.startswith('Modo de prueba') and '19/11/2026 00:00' in antes
    assert 'terminó' in despues


def test_servidor_en_utc_respeta_hora_de_mexico(ventana_19):
    # Render trabaja en UTC: las 00:00 del 19 en México son las 06:00 UTC.
    assert not estado_registro(datetime(2026, 11, 19, 5, 59, tzinfo=timezone.utc)).activo
    assert estado_registro(datetime(2026, 11, 19, 6, 0, tzinfo=timezone.utc)).activo


def test_sin_fechas_no_hay_limite(monkeypatch, tmp_path):
    monkeypatch.setenv('PSICOLAB_DATA_DIR', str(tmp_path))
    monkeypatch.delenv('PSICOLAB_GUARDAR_DESDE', raising=False)
    monkeypatch.delenv('PSICOLAB_GUARDAR_HASTA', raising=False)
    assert estado_registro(mx('2030-01-01 03:00')).activo


@pytest.mark.parametrize('carpeta', [None, 'no_existe'])
def test_sin_carpeta_de_datos_no_guarda(ventana_19, monkeypatch, tmp_path, carpeta):
    if carpeta is None:
        monkeypatch.delenv('PSICOLAB_DATA_DIR')
    else:
        monkeypatch.setenv('PSICOLAB_DATA_DIR', str(tmp_path / carpeta))
    estado = estado_registro(mx('2026-11-19 10:00'))
    assert not estado.activo and 'no está configurado' in estado.mensaje
    assert not (tmp_path / 'no_existe').exists()


@pytest.mark.parametrize('desde,hasta', [
    ('19/11/2026', ''),
    ('2026-11-19', ''),
    ('2026-11-19T18:30', '2026-11-19T00:00'),
])
def test_fechas_mal_configuradas(monkeypatch, desde, hasta):
    monkeypatch.setenv('PSICOLAB_GUARDAR_DESDE', desde)
    monkeypatch.setenv('PSICOLAB_GUARDAR_HASTA', hasta)
    with pytest.raises(ValueError):
        leer_ventana()
