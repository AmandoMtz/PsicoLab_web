import { guardarSesion } from '../sesion.js';
import { calcularResultado } from '../api.js';
import { estado, preguntasFaltantes } from '../estado.js';
import { DIMENSIONES, PREGUNTAS_POR_DIMENSION } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';

const TEMAS = ['Cómo te relacionas', 'Cómo descubres', 'Cómo decides', 'Cómo te organizas'];
const PISTAS = ['Piensa en cómo prefieres compartir tu tiempo y tu energía.', 'Piensa en qué suele llamar tu atención cuando conoces algo nuevo.', 'Piensa en qué te ayuda a elegir entre distintas posibilidades.', 'Piensa en cómo prefieres llevar tus planes y actividades.'];

export function mostrarCuestionario(contenedor, app) {
  const { preguntas } = app.catalogo;
  const total = preguntas.length;
  const grupos = Math.ceil(total / PREGUNTAS_POR_DIMENSION);
  let grupo = Math.floor((preguntasFaltantes(total)[0] ?? 0) / PREGUNTAS_POR_DIMENSION);
  let enviando = false;
  const cuerpo = el('div', { class: 'grupo-preguntas' });
  const titulo = el('h2', { class: 'titulo-grupo', tabindex: '-1' });
  const pista = el('p', { class: 'pista-grupo' });
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const barra = el('div', { class: 'progreso-barra' });
  const progreso = el('div', { class: 'progreso', role: 'progressbar', 'aria-label': 'Preguntas respondidas', 'aria-valuemin': '0', 'aria-valuemax': String(total), 'aria-valuenow': '0' }, barra);
  const contador = el('p', { class: 'progreso-texto', role: 'status', 'aria-live': 'polite' });
  const anterior = boton('← Anterior', () => { if (grupo > 0) cambiar(grupo - 1); else app.ir('datos'); });
  const siguiente = boton('Siguiente bloque →', avanzar, 'primario');
  const pasos = Array.from({ length: grupos }, (_, i) => boton('', () => cambiar(i), 'grupo'));
  pasos.forEach((b) => b.classList.add('paso-grupo'));
  const vista = pantalla('cuestionario',
    el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, 'PASO 03 / TUS PREFERENCIAS'), el('h1', { class: 'titulo-pantalla' }, 'Aquí no hay respuestas incorrectas.'), el('p', { class: 'subtitulo' }, 'Elige la opción que más se parezca a ti, aunque ninguna te describa por completo.')),
    el('div', { class: 'cuestionario-layout' },
      el('aside', { class: 'mapa-cuestionario' }, el('p', { class: 'sobrelinea' }, 'TU RECORRIDO'), el('nav', { 'aria-label': 'Bloques del cuestionario' }, pasos), el('div', { class: 'resumen-progreso' }, contador, progreso, el('p', { class: 'microtexto' }, 'Puedes volver y cambiar tus respuestas.'))),
      panel({ clase: 'panel-preguntas' }, el('div', { class: 'cabecera-grupo' }, titulo, pista), cuerpo, aviso,
        el('div', { class: 'acciones pie-cuestionario' }, anterior, siguiente))));
  contenedor.append(vista);

  function actualizar() {
    const n = total - preguntasFaltantes(total).length;
    barra.style.width = `${100 * n / total}%`;
    progreso.setAttribute('aria-valuenow', String(n));
    contador.textContent = `${n} de ${total} respuestas`;
    pasos.forEach((b, i) => {
      const inicio = i * PREGUNTAS_POR_DIMENSION;
      const fin = Math.min(inicio + PREGUNTAS_POR_DIMENSION, total);
      const hechas = preguntas.slice(inicio, fin).filter((_, j) => estado.respuestas[inicio + j]).length;
      b.replaceChildren(el('span', { class: 'numero-bloque', 'aria-hidden': 'true' }, hechas === fin - inicio ? '✓' : String(i + 1)), el('span', { class: 'nombre-bloque' }, TEMAS[i], el('small', {}, `${hechas} / ${fin - inicio} respuestas`)));
      b.classList.toggle('activo', i === grupo);
      if (i === grupo) b.setAttribute('aria-current', 'step'); else b.removeAttribute('aria-current');
      b.disabled = enviando;
    });
  }
  function cambiar(nuevo, enfocar = true) {
    if (enviando) return;
    grupo = nuevo;
    aviso.textContent = '';
    titulo.textContent = `${String(grupo + 1).padStart(2, '0')} · ${TEMAS[grupo]}`;
    pista.textContent = PISTAS[grupo];
    const inicio = grupo * PREGUNTAS_POR_DIMENSION;
    cuerpo.replaceChildren(...preguntas.slice(inicio, inicio + PREGUNTAS_POR_DIMENSION).map((p, offset) => {
      const i = inicio + offset;
      const bloque = el('fieldset', { class: `pregunta${estado.respuestas[i] ? ' respondida' : ''}`, id: `bloque-${i}` },
        el('legend', { class: 'pregunta-texto' }, el('span', { class: 'numero-reactivo' }, String(i + 1).padStart(2, '0')), p.pregunta),
        el('div', { class: 'opciones' }, ['A', 'B'].map((letra) => el('label', { class: 'opcion' },
          el('input', { type: 'radio', name: `pregunta-${i}`, value: letra, checked: estado.respuestas[i] === letra,
            onchange: () => {
              estado.respuestas[i] = letra; estado.resultado = null;
              bloque.classList.add('respondida'); aviso.textContent = ''; actualizar(); guardarSesion('cuestionario');
            } }),
          el('span', { class: 'letra-opcion', 'aria-hidden': 'true' }, letra), el('span', {}, p[letra])))));
      return bloque;
    }));
    anterior.textContent = grupo === 0 ? '← Sobre ti' : '← Bloque anterior';
    siguiente.textContent = grupo === grupos - 1 ? 'Descubrir mi perfil ✦' : 'Siguiente bloque →';
    actualizar();
    if (enfocar) { titulo.focus({ preventScroll: true }); titulo.scrollIntoView({ block: 'start' }); }
  }
  async function avanzar() {
    if (enviando) return;
    const faltantes = preguntasFaltantes(total).filter(i => grupo === grupos - 1 || Math.floor(i / PREGUNTAS_POR_DIMENSION) === grupo);
    if (faltantes.length) {
      const i = faltantes[0];
      cambiar(Math.floor(i / PREGUNTAS_POR_DIMENSION), false);
      aviso.textContent = `Todavía falta responder: ${faltantes.map(n => n + 1).join(', ')}. Elige una opción para continuar.`;
      const input = cuerpo.querySelector(`input[name="pregunta-${i}"]`);
      input.focus();
      return;
    }
    if (grupo < grupos - 1) { cambiar(grupo + 1); return; }
    enviando = true; actualizar();
    vista.querySelectorAll('button, input').forEach(n => n.disabled = true);
    siguiente.textContent = 'Preparando tu perfil…'; siguiente.setAttribute('aria-busy', 'true');
    try {
      estado.registroId ||= crypto.randomUUID();
      guardarSesion('cuestionario');
      const resultado = await calcularResultado({ consentimiento: true, edad: Number(estado.edad), sexo: estado.sexo,
        carrera: estado.carrera, respuestas: preguntas.map((_, i) => estado.respuestas[i]), registro_id: estado.registroId });
      if (!vista.isConnected) return;
      estado.resultado = resultado;
      if (resultado.registro.guardado) estado.registroId = resultado.registro.id;
      app.ir('resultado');
    } catch (error) {
      if (!vista.isConnected) return;
      aviso.textContent = error.message;
      enviando = false;
      vista.querySelectorAll('button, input').forEach(n => n.disabled = false);
      siguiente.textContent = 'Reintentar mi resultado'; siguiente.removeAttribute('aria-busy');
      actualizar();
    }
  }
  cambiar(grupo, false);
}
