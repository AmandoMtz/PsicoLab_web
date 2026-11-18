import { boton, el, pantalla } from '../ui.js';
import { estado } from '../estado.js';

export function mostrarInicio(contenedor, app) {
  const continuar = estado.consentimiento;
  contenedor.append(pantalla('inicio',
    el('section', { class: 'hero' },
      el('div', { class: 'hero-texto' },
        el('p', { class: 'sobrelinea' }, el('span', { class: 'punto' }), 'TU CURIOSIDAD TIENE MUCHO QUE CONTAR'),
        el('h1', {}, 'Tú pones las respuestas.', el('span', { class: 'acento' }, 'La IA, otra perspectiva.')),
        el('p', { class: 'descripcion' }, '¿Puede un algoritmo conocerte? Explora tus preferencias, descubre el perfil que estima una red neuronal y conecta el resultado con tu carrera.'),
        el('div', { class: 'hero-acciones' }, boton(continuar ? 'Continuar mi recorrido →' : 'Comenzar mi recorrido →', () => app.ir(continuar ? 'cuestionario' : 'consentimiento'), 'primario')),
        el('div', { class: 'hero-datos' },
          el('div', {}, el('strong', {}, '20'), el('span', {}, 'preguntas sobre ti')),
          el('div', {}, el('strong', {}, '16'), el('span', {}, 'perfiles para explorar')))),
      el('div', { class: 'hero-visual', 'aria-label': 'Ejemplos de tarjetas de perfiles, no son tu resultado' },
        el('span', { class: 'orbita orbita-uno', 'aria-hidden': 'true' }),
        el('span', { class: 'orbita orbita-dos', 'aria-hidden': 'true' }),
        el('span', { class: 'etiqueta-flotante' }, 'Hay más de una forma de ser tú ✦'),
        el('img', { class: 'tarjeta-demo tarjeta-atras', src: '/tarjetas/ENFP.png', alt: 'Ejemplo de tarjeta ENFP', width: '800', height: '1000', decoding: 'async' }),
        el('img', { class: 'tarjeta-demo tarjeta-frente', src: '/tarjetas/INTP.png', alt: 'Ejemplo de tarjeta INTP', width: '800', height: '1000', decoding: 'async' }))),
    el('section', { class: 'como-funciona', 'aria-labelledby': 'como-titulo' },
      el('div', { class: 'seccion-intro' }, el('h2', { id: 'como-titulo' }, 'Un recorrido pensado para ti.')),
      el('div', { class: 'pasos-inicio' },
        paso('01', 'Decide participar', 'Lee el consentimiento y decide si quieres continuar.', 'rosa'),
        paso('02', 'Responde a tu manera', 'Elige lo que más se parezca a ti. No hay respuestas correctas.', 'lila'),
        paso('03', 'Explora posibilidades', 'Conoce tu tarjeta, explora áreas de tu carrera y participa en tres retos.', 'menta'))),
    el('aside', { class: 'aviso-suave' }, el('span', { class: 'icono-nota', 'aria-hidden': 'true' }, 'i'), el('p', {}, 'Esta actividad es exploratoria; no constituye diagnóstico ni orientación laboral o profesional validada.'))));
}
function paso(numero, titulo, texto, color) {
  return el('article', { class: `paso-inicio ${color}` }, el('span', { class: 'numero-paso' }, numero), el('div', {}, el('h3', {}, titulo), el('p', {}, texto)));
}
