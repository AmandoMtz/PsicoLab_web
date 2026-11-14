import { ajustarAlTexto, boton, el, panel, pantalla } from '../ui.js';

export function mostrarInicio(contenedor, app) {
  const total = app.catalogo.preguntas.length;
  contenedor.append(pantalla('inicio', panel({ franja: 'amarilla' }, el('div', { class: 'bienvenida' },
    el('h1', {}, '¿Puede un algoritmo conocerte?'),
    ajustarAlTexto(el('p', { class: 'descripcion' },
      `Descubre el perfil que predice una red neuronal a partir de ${total} respuestas `
      + 'y explora tres áreas profesionales relacionadas con tu carrera.')),
    el('div', { class: 'chips' },
      el('span', { class: 'chip chip-amarillo' }, `${total} reactivos`),
      el('span', { class: 'chip chip-rosa' }, '16 perfiles'),
      el('span', { class: 'chip chip-azul' }, '3 opciones laborales')),
    el('p', { class: 'nota' }, 'Actividad de divulgación; no constituye diagnóstico ni orientación laboral validada.'),
    boton('Comenzar →', () => app.ir('consentimiento'), 'primario')))));
}
