import { EDAD_MAXIMA, EDAD_MINIMA, SEXOS, datosCompletos, estado } from '../estado.js';
import { boton, el, panel, pantalla } from '../ui.js';

function selector(clave, etiqueta, opciones) {
  const select = el('select', { id: clave, required: true },
    el('option', { value: '', hidden: true }),
    opciones.map((valor) => el('option', { value: valor }, valor)));
  select.value = estado[clave];
  select.addEventListener('change', () => {
    estado[clave] = select.value;
    estado.resultado = null;
  });
  return el('div', { class: 'campo' }, el('label', { for: clave }, `${etiqueta} *`), select);
}

export function mostrarDatos(contenedor, app) {
  const { carreras } = app.catalogo;
  const edades = Array.from({ length: EDAD_MAXIMA - EDAD_MINIMA + 1 }, (_, i) => String(EDAD_MINIMA + i));
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const continuar = () => {
    if (datosCompletos(carreras)) app.ir('cuestionario');
    else aviso.textContent = 'Completa edad, sexo y licenciatura o carrera antes de continuar.';
  };
  contenedor.append(pantalla('datos', panel({ franja: 'rosa' },
    el('h1', { class: 'titulo-pantalla' }, 'Datos generales'),
    el('p', { class: 'subtitulo' }, 'Selecciona los tres campos obligatorios antes de iniciar el cuestionario.'),
    el('div', { class: 'campos' },
      selector('edad', `Edad (${EDAD_MINIMA} a ${EDAD_MAXIMA} años)`, edades),
      selector('sexo', 'Sexo', SEXOS),
      selector('carrera', 'Licenciatura o carrera', carreras)),
    aviso,
    el('div', { class: 'acciones' },
      boton('← Consentimiento', () => app.ir('consentimiento')),
      boton('Ir al cuestionario →', continuar, 'primario')))));
}
