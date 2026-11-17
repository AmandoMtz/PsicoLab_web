"""Respuestas web en Supabase. Solo biblioteca estándar; clave en el servidor."""
import json
import os
import re
from urllib.request import Request, build_opener, HTTPRedirectHandler
from urllib.error import HTTPError, URLError
from uuid import UUID, uuid4


def seleccionado():
    # Una configuración incompleta nunca debe caer silenciosamente en SQLite.
    return bool(os.getenv('SUPABASE_URL', '').strip() or
                os.getenv('SUPABASE_SECRET_KEY', '').strip())


def configuracion():
    url = os.getenv('SUPABASE_URL', '').strip().rstrip('/')
    key = os.getenv('SUPABASE_SECRET_KEY', '').strip()
    if not re.fullmatch(r'https://[a-z0-9-]+\.supabase\.co', url):
        raise ValueError('Configura SUPABASE_URL con la URL HTTPS del proyecto Supabase.')
    if not key.startswith('sb_secret_') or len(key) < 20:
        raise ValueError('Configura SUPABASE_SECRET_KEY con una clave secreta sb_secret_.')
    return url, key


class SinRedireccion(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def _request(method, query='', payload=None, prefer=None):
    url, key = configuracion()
    headers = {'apikey': key, 'Content-Type': 'application/json',
               'Accept': 'application/json'}
    if prefer:
        headers['Prefer'] = prefer
    data = None if payload is None else json.dumps(payload).encode('utf-8')
    request = Request(url + '/rest/v1/respuestas' + query,
                      data=data, headers=headers, method=method)
    try:
        with build_opener(SinRedireccion()).open(request, timeout=12) as response:
            raw = response.read()
    except HTTPError as error:
        # No exponer cuerpos remotos: pueden contener datos de participantes.
        status = error.code
        error.close()
        detail = {401: 'Revisa la clave secreta.',
                  403: 'Revisa los permisos de service_role.',
                  404: 'Revisa la tabla respuestas y que Data API esté habilitada.',
                  400: 'Revisa las columnas y restricciones de la tabla.'}.get(
                      status, 'Revisa el estado del proyecto Supabase.')
        raise RuntimeError(f'Supabase HTTP {status}. {detail}') from None
    except (URLError, TimeoutError, OSError):
        raise RuntimeError('No se pudo conectar con Supabase. Intenta nuevamente.') from None
    if not raw:
        return None
    try:
        return json.loads(raw)
    except (ValueError, UnicodeDecodeError):
        raise RuntimeError('Supabase devolvió una respuesta no válida.') from None


def comprobar():
    _request('GET', '?select=id&limit=0')


def save(answers, career, profile_id, profile, existing=None, *, age=None, sex=None):
    from psicolab_core import profiles, careers
    if (len(answers) != 20 or any(a not in ('A', 'B') for a in answers)
            or profiles().get(profile_id) != profile or career not in careers()
            or type(age) is not int or not 17 <= age <= 65
            or sex not in ('Masculino', 'Femenino')):
        raise ValueError('Registro inválido para Supabase.')
    ident = str(UUID(existing)) if existing else str(uuid4())
    row = dict(id=ident, edad=age, sexo=sex, carrera=career,
               respuestas=list(answers), perfil_id=profile_id, perfil=profile, origen='real')
    # No enviar fecha: conserva la original al actualizar y usa DEFAULT al insertar.
    result = _request('POST', '?on_conflict=id&select=id', row,
                      'resolution=merge-duplicates,return=representation')
    if not isinstance(result, list) or len(result) != 1 or result[0].get('id') != ident:
        raise RuntimeError('Supabase no confirmó el guardado. Intenta nuevamente.')
    return ident


def remove(identifier):
    ident = str(UUID(str(identifier)))
    _request('DELETE', '?id=eq.' + ident, prefer='return=minimal')
