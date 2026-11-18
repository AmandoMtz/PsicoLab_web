import { EDAD_MAXIMA, EDAD_MINIMA, SEXOS, datosCompletos, estado } from '../estado.js';
import { boton, el, panel, pantalla } from '../ui.js';
import { FACULTAD, etiquetaCarrera, iconoCarrera, ordenarCarreras } from '../carreras.js';

function selector(clave, etiqueta, opciones) {
  const select = el('select', { id: clave, required: true },
    el('option', { value: '', disabled: true }, 'Selecciona una opción'),
    opciones.map((valor) => el('option', { value: valor }, valor)));
  select.value = estado[clave];
  select.addEventListener('change', () => { estado[clave] = select.value; estado.resultado = null; estado.retos = null; });
  return el('div', { class: 'campo' }, el('label', { for: clave }, `${etiqueta} *`), select);
}

export function mostrarDatos(contenedor, app) {
  const edades = Array.from({ length: EDAD_MAXIMA - EDAD_MINIMA + 1 }, (_, i) => String(EDAD_MINIMA + i));
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const elegirCarrera = (carrera) => { estado.carrera = carrera; estado.resultado = null; estado.retos = null; };
  const carreras = ordenarCarreras(app.catalogo.carreras).map((carrera) => {
    const input = el('input', { type: 'radio', name: 'carrera', value: carrera, checked: estado.carrera === carrera });
    input.addEventListener('change', () => elegirCarrera(carrera));
    input.addEventListener('click', () => elegirCarrera(carrera));
    return el('label', { class: 'carrera-opcion' }, input,
      el('span', { class: 'carrera-icono', 'aria-hidden': 'true' }, iconoCarrera(carrera)),
      el('span', { class: 'carrera-nombre' }, etiquetaCarrera(carrera)));
  });

  // Qué datos faltan, con el nombre que ve la persona.
  const faltantes = () => {
    const lista = [];
    if (!estado.edad) lista.push(['edad', 'tu edad']);
    if (!estado.sexo) lista.push(['sexo', 'tu género de nacimiento']);
    if (!app.catalogo.carreras.includes(estado.carrera)) lista.push(['carrera', 'tu carrera']);
    return lista;
  };
  const marcar = () => {
    const pendientes = faltantes().map(([clave]) => clave);
    for (const clave of ['edad', 'sexo']) contenedor.querySelector(`#${clave}`)?.closest('.campo')?.classList.toggle('falta', pendientes.includes(clave));
    contenedor.querySelector('.carreras')?.classList.toggle('falta', pendientes.includes('carrera'));
    return pendientes;
  };
  const revisar = () => {
    if (!aviso.textContent) return;
    if (datosCompletos(app.catalogo.carreras)) { aviso.textContent = ''; marcar(); return; }
    const lista = faltantes();
    if (lista.length) aviso.textContent = `Te falta elegir: ${lista.map(([, texto]) => texto).join(', ')}.`;
    marcar();
  };
  const continuar = () => {
    if (datosCompletos(app.catalogo.carreras)) { app.ir('cuestionario'); return; }
    const lista = faltantes();
    aviso.textContent = lista.length
      ? `Te falta elegir: ${lista.map(([, texto]) => texto).join(', ')}.`
      : `Revisa tus datos: la edad debe estar entre ${EDAD_MINIMA} y ${EDAD_MAXIMA} años.`;
    const primero = marcar()[0] ?? 'edad';
    const destino = primero === 'carrera' ? contenedor.querySelector('.carreras') : contenedor.querySelector(`#${primero}`);
    destino?.scrollIntoView({ block: 'center' });
    (primero === 'carrera' ? contenedor.querySelector('input[name="carrera"]') : destino)?.focus({ preventScroll: true });
  };

  const formulario = panel({ clase: 'formulario-datos' },
    el('div', { class: 'campos' }, selector('edad', 'Edad', edades), selector('sexo', 'Género de nacimiento', SEXOS)),
    el('fieldset', { class: 'carreras' }, el('legend', {}, '¿Qué carrera estudias? *'), el('p', { class: 'facultad' }, FACULTAD), el('div', { class: 'carreras-grid' }, carreras)),
    aviso,
    el('div', { class: 'acciones' }, boton('← Volver', () => app.ir('consentimiento')), boton('Ir a las preguntas →', continuar, 'primario')));
  formulario.addEventListener('change', revisar);
  formulario.addEventListener('click', () => setTimeout(revisar, 0));
  contenedor.append(pantalla('datos',
    el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, 'PASO 2 / SOBRE TI'), el('h1', { class: 'titulo-pantalla' }, 'Hagámoslo más personal.')),
    el('div', { class: 'datos-layout' }, formulario,
      el('aside', { class: 'datos-nota' }, el('span', { class: 'icono-grande', 'aria-hidden': 'true' }, '✦'), el('h2', {}, 'Tu perfil empieza con tus respuestas.'), el('p', {}, 'La IA utiliza únicamente las 20 respuestas del cuestionario. Tu edad, género de nacimiento y carrera no cambian el perfil calculado.'), el('p', {}, 'La carrera permite mostrar áreas de trabajo. En los retos, el modelo también utiliza tu edad y género de nacimiento.'), el('span', { class: 'mini-pill' }, 'Sin nombres ni correos')))));
}
