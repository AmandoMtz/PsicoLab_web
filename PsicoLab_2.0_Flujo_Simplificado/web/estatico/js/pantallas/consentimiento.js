import { estado, reiniciar } from '../estado.js';
import { CONSENTIMIENTO_PARRAFOS, CONSENTIMIENTO_TITULO } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';

export function mostrarConsentimiento(contenedor, app) {
  const aceptar = () => { estado.consentimiento = true; app.ir('datos'); };
  const rechazar = () => { reiniciar(); app.ir('rechazo'); };
  contenedor.append(pantalla('consentimiento',
    el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, 'PASO 01 / TU DECISIÓN'), el('h1', { class: 'titulo-pantalla' }, 'Tú decides participar.'), el('p', { class: 'subtitulo' }, 'Lee la información completa antes de elegir. Puedes aceptar o salir de la actividad.')),
    panel({},
      el('div', { class: 'texto-consentimiento', tabindex: '0' },
        el('h2', {}, CONSENTIMIENTO_TITULO),
        el('div', { class: 'parrafos' }, CONSENTIMIENTO_PARRAFOS.map((parrafo) => el('p', {}, parrafo)))),
      el('div', { class: 'pie-panel' },
        boton('No acepto', rechazar, 'naranja'),
        boton('Sí, acepto y autorizo', aceptar, 'primario')))));
}

export function mostrarRechazo(contenedor, app) {
  // "Volver al inicio" equivale al botón "Salir" de escritorio: se descarta la sesión.
  const volver = () => { reiniciar(); app.ir('inicio'); };
  contenedor.append(pantalla('rechazo', panel({},
    el('h1', { class: 'titulo-pantalla' }, 'No se autorizó la participación'),
    el('p', { class: 'explicacion' },
      'El cuestionario no se abrirá ni se guardarán respuestas. '
      + 'Puedes volver a leer el consentimiento o regresar al inicio.'),
    el('div', { class: 'acciones' },
      boton('Revisar consentimiento', () => app.ir('consentimiento')),
      boton('Volver al inicio', volver, 'marino')))));
}
