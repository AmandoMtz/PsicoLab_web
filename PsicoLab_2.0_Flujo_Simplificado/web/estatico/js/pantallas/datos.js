import { EDAD_MAXIMA, EDAD_MINIMA, SEXOS, datosCompletos, estado } from '../estado.js';
import { boton, el, panel, pantalla } from '../ui.js';
import { FACULTAD, etiquetaCarrera, iconoCarrera, ordenarCarreras } from '../carreras.js';

function selector(clave, etiqueta, opciones) {
  const select = el('select', { id: clave, required: true },
    el('option', { value: '', disabled: true }, 'Selecciona una opción'),
    opciones.map((valor) => el('option', { value: valor }, valor)));
  select.value = estado[clave];
  select.addEventListener('change', () => { estado[clave] = select.value; estado.resultado = null; });
  return el('div', { class: 'campo' }, el('label', { for: clave }, `${etiqueta} *`), select);
}

export function mostrarDatos(contenedor, app) {
  const edades = Array.from({ length: EDAD_MAXIMA - EDAD_MINIMA + 1 }, (_, i) => String(EDAD_MINIMA + i));
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const carreras = ordenarCarreras(app.catalogo.carreras).map((carrera) => el('label', { class: 'carrera-opcion' },
    el('input', { type: 'radio', name: 'carrera', value: carrera, checked: estado.carrera === carrera,
      onchange: () => { estado.carrera = carrera; estado.resultado = null; } }),
    el('span', { class: 'carrera-icono', 'aria-hidden': 'true' }, iconoCarrera(carrera)),
    el('span', { class: 'carrera-nombre' }, etiquetaCarrera(carrera))));
  const continuar = () => {
    if (datosCompletos(app.catalogo.carreras)) app.ir('cuestionario');
    else {
      aviso.textContent = 'Completa tu edad, sexo y carrera para continuar.';
      const pendiente = !estado.edad ? '#edad' : !estado.sexo ? '#sexo' : 'input[name="carrera"]';
      contenedor.querySelector(pendiente)?.focus();
    }
  };
  contenedor.append(pantalla('datos',
    el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, 'PASO 02 / SOBRE TI'), el('h1', { class: 'titulo-pantalla' }, 'Hagámoslo más personal.'), el('p', { class: 'subtitulo' }, 'Tu carrera nos ayuda a mostrarte áreas profesionales que tengan sentido para ti.')),
    el('div', { class: 'datos-layout' }, panel({ clase: 'formulario-datos' },
      el('div', { class: 'campos' }, selector('edad', 'Edad', edades), selector('sexo', 'Sexo', SEXOS)),
      el('fieldset', { class: 'carreras' }, el('legend', {}, '¿Qué carrera estudias? *'), el('p', { class: 'facultad' }, FACULTAD), el('div', { class: 'carreras-grid' }, carreras)),
      aviso,
      el('div', { class: 'acciones' }, boton('← Volver', () => app.ir('consentimiento')), boton('Ir a las preguntas →', continuar, 'primario'))),
      el('aside', { class: 'datos-nota' }, el('span', { class: 'icono-grande', 'aria-hidden': 'true' }, '✦'), el('h2', {}, 'Tu perfil empieza con tus respuestas.'), el('p', {}, 'La IA utiliza únicamente las 20 respuestas del cuestionario. Tu edad, sexo y carrera no cambian el perfil calculado.'), el('p', {}, 'La carrera se utiliza después para elegir tres áreas de trabajo que puedes explorar.'), el('span', { class: 'mini-pill' }, 'Sin nombres ni correos')))));
}
