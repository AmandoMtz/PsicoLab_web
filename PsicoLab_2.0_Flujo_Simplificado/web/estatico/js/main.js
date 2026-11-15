import { obtenerCatalogo } from './api.js';
import { datosCompletos, estado } from './estado.js';
import { boton, el, panel, pantalla, vigilarDesborde } from './ui.js';
import { mostrarInicio } from './pantallas/inicio.js';
import { mostrarConsentimiento, mostrarRechazo } from './pantallas/consentimiento.js';
import { mostrarDatos } from './pantallas/datos.js';
import { mostrarCuestionario } from './pantallas/cuestionario.js';
import { mostrarResultado } from './pantallas/resultado.js';

import { guardarSesion, recuperarSesion } from './sesion.js';

const PANTALLAS = {
  inicio: mostrarInicio,
  consentimiento: mostrarConsentimiento,
  rechazo: mostrarRechazo,
  datos: mostrarDatos,
  cuestionario: mostrarCuestionario,
  resultado: mostrarResultado,
};

const contenedor = document.getElementById('app');
const app = { catalogo: null, ir };
let limpiezas = [];
document.addEventListener('change', () => guardarSesion());
// El logotipo lleva siempre al inicio; el avance de la sesión se conserva.
document.querySelector('.identidad')?.addEventListener('click', (evento) => {
  if (!app.catalogo || evento.button !== 0 || evento.ctrlKey || evento.metaKey || evento.shiftKey) return;
  evento.preventDefault();
  if (history.state?.pantalla === 'inicio') window.scrollTo({ top: 0, behavior: 'smooth' });
  else ir('inicio');
});
window.addEventListener('pagehide', () => guardarSesion());

// Mismas reglas que la app de escritorio: sin consentimiento no hay datos ni
// cuestionario, y sin datos generales no hay cuestionario ni resultado.
function pantallaPermitida(nombre) {
  if (['datos', 'cuestionario', 'resultado'].includes(nombre) && !estado.consentimiento) return 'consentimiento';
  if (['cuestionario', 'resultado'].includes(nombre) && !datosCompletos(app.catalogo.carreras)) return 'datos';
  if (nombre === 'resultado' && !estado.resultado) return 'cuestionario';
  return Object.hasOwn(PANTALLAS, nombre) ? nombre : 'inicio';
}

function ir(nombre, { historial = true } = {}) {
  const destino = pantallaPermitida(nombre);
  limpiezas.forEach((limpiar) => limpiar());
  limpiezas = [];
  contenedor.replaceChildren();
  PANTALLAS[destino](contenedor, app);
  contenedor.querySelectorAll('.desplazable').forEach((nodo) => limpiezas.push(vigilarDesborde(nodo)));
  const titulo = contenedor.querySelector('h1');
  if (titulo) { titulo.tabIndex = -1; titulo.focus({ preventScroll: true }); }
  document.title = `${titulo?.textContent || 'Inicio'} | PsicoLab 2.0`;
  pintarRecorrido(destino);
  guardarSesion(destino);
  window.scrollTo(0, 0);
  // Guardar cada pantalla en el historial hace que el botón "Atrás" del
  // navegador o del celular regrese a la pantalla anterior sin salir del sitio.
  if (historial) history.pushState({ pantalla: destino }, '');
  else history.replaceState({ pantalla: destino }, '');
}

function pintarRecorrido(destino) {
  const nav = document.getElementById('recorrido');
  nav.hidden = ['inicio', 'rechazo'].includes(destino);
  const pasos = [['consentimiento', 'Tu decisión'], ['datos', 'Sobre ti'], ['cuestionario', 'Tus preferencias'], ['resultado', 'Tu perfil']];
  const actual = pasos.findIndex(([clave]) => clave === destino);
  nav.replaceChildren(el('ol', {}, pasos.map(([clave, texto], i) => {
    const item = el('li', { class: i === actual ? 'actual' : i < actual ? 'completo' : '' },
      el('span', { class: 'paso-indice', 'aria-hidden': 'true' }, i < actual ? '✓' : String(i + 1)),
      el('span', {}, texto));
    if (i === actual) item.setAttribute('aria-current', 'step');
    return item;
  })));
}

window.addEventListener('popstate', (evento) => {
  if (app.catalogo) ir(evento.state?.pantalla ?? 'inicio', { historial: false });
});

async function arrancar() {
  contenedor.replaceChildren(el('p', { class: 'cargando' }, 'Cargando PsicoLab…'));
  try {
    app.catalogo = await obtenerCatalogo();
  } catch (error) {
    contenedor.replaceChildren(pantalla('rechazo', panel({},
      el('h1', { class: 'titulo-pantalla' }, 'No se pudo cargar el cuestionario'),
      el('p', { class: 'explicacion' }, error.message),
      el('div', { class: 'acciones' }, boton('Reintentar', arrancar, 'primario')))));
    return;
  }
  ir(recuperarSesion(app.catalogo.carreras) || 'inicio', { historial: false });
}

arrancar();
