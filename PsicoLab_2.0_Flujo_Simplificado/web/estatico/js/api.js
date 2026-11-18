// Comunicación con el servidor (mismo origen: no requiere configuración extra).

async function pedir(ruta, opciones = {}) {
  let respuesta;
  try {
    respuesta = await fetch(ruta, opciones);
  } catch {
    throw new Error('No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.');
  }
  if (!respuesta.ok) {
    const cuerpo = await respuesta.json().catch(() => ({}));
    const detalle = typeof cuerpo.detail === 'string' ? cuerpo.detail : '';
    throw new Error(detalle || `El servidor respondió con un error (${respuesta.status}). Inténtalo de nuevo.`);
  }
  return respuesta.status === 204 ? null : respuesta.json();
}

export function obtenerCatalogo() {
  return pedir('/api/catalogo');
}

export function calcularResultado(datos) {
  return pedir('/api/resultado', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(datos),
  });
}

export function eliminarRegistro(id) {
  return pedir(`/api/registros/${encodeURIComponent(id)}`, { method: 'DELETE' });
}

export function iniciarRetos(registroId) {
  return pedir('/api/retos/iniciar', { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ registro_id: registroId }) });
}
export function finalizarRetos(retoId, decisiones) {
  return pedir('/api/retos/finalizar', { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reto_id: retoId, decisiones }) });
}
