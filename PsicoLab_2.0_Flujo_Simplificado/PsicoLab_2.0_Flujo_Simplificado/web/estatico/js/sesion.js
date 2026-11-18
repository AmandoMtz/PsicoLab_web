// Solo esta pestaña. Nunca usamos localStorage ni enviamos borradores al servidor.
import { estado } from './estado.js';
const CLAVE = 'psicolab.sesion.v1';
const DURACION = 2 * 60 * 60 * 1000;
export function guardarSesion(pantalla = null) {
  try {
    if (!estado.consentimiento) { sessionStorage.removeItem(CLAVE); return; }
    const anterior = JSON.parse(sessionStorage.getItem(CLAVE) || 'null');
    sessionStorage.setItem(CLAVE, JSON.stringify({
      version: 1, vence: Date.now() + DURACION,
      pantalla: pantalla || anterior?.pantalla || 'datos', datos: estado,
    }));
  } catch { /* La actividad funciona aunque el navegador bloquee el almacenamiento. */ }
}
export function recuperarSesion(carreras) {
  try {
    const guardado = JSON.parse(sessionStorage.getItem(CLAVE) || 'null');
    if (!guardado || guardado.version !== 1 || guardado.vence <= Date.now()) throw new Error();
    const d = guardado.datos;
    if (d?.consentimiento !== true || !d.respuestas || typeof d.respuestas !== 'object') throw new Error();
    const respuestas = {};
    for (const [k, v] of Object.entries(d.respuestas)) {
      if (!/^(?:[0-9]|1[0-9])$/.test(k) || !['A', 'B'].includes(v)) throw new Error();
      respuestas[k] = v;
    }
    const id = typeof d.registroId === 'string' && /^[0-9a-f-]{36}$/i.test(d.registroId) ? d.registroId : null;
    Object.assign(estado, { consentimiento: true,
      edad: Number.isInteger(Number(d.edad)) && Number(d.edad) >= 17 && Number(d.edad) <= 65 ? String(d.edad) : '',
      sexo: ['Masculino', 'Femenino'].includes(d.sexo) ? d.sexo : '',
      carrera: carreras.includes(d.carrera) ? d.carrera : '', respuestas, registroId: id,
      resultado: null, retos: d.retos && /^[0-9a-f-]{36}$/i.test(d.retos.reto_id)
        && Array.isArray(d.retos.decisiones) && d.retos.decisiones.length <= 3
        && d.retos.decisiones.every(v => ['A', 'B', 'C'].includes(v))
        ? { reto_id: d.retos.reto_id, decisiones: d.retos.decisiones } : null });
    // Los resultados se vuelven a calcular; el identificador evita duplicar el registro.
    return ['resultado', 'retos_intro', 'retos', 'retos_resultado'].includes(guardado.pantalla) ? 'cuestionario' : guardado.pantalla;
  } catch { try { sessionStorage.removeItem(CLAVE); } catch {} return 'inicio'; }
}
