import { guardarSesion } from '../sesion.js';
import { calcularResultado } from '../api.js';
import { estado, preguntasFaltantes } from '../estado.js';
import { PREGUNTAS_POR_DIMENSION } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';

const TEMAS = ['Cómo te relacionas', 'Cómo descubres', 'Cómo decides', 'Cómo te organizas'];
const PISTAS = ['Piensa en cómo prefieres compartir tu tiempo y tu energía.', 'Piensa en qué suele llamar tu atención cuando conoces algo nuevo.', 'Piensa en qué te ayuda a elegir entre distintas posibilidades.', 'Piensa en cómo prefieres llevar tus planes y actividades.'];
const AVANCE_MS = 450;

// Una pregunta por pantalla: al tocar una opción se marca con fuerza y,
// tras un instante, se pasa sola a la siguiente.
export function mostrarCuestionario(contenedor, app) {
  const { preguntas } = app.catalogo;
  const total = preguntas.length;
  let actual = preguntasFaltantes(total)[0] ?? 0;
  let enviando = false;
  let reintento = false;
  let temporizador = null;

  const chip = el('span', { class: 'tema-chip' });
  const numero = el('p', { class: 'pregunta-numero', role: 'status', 'aria-live': 'polite' });
  const pista = el('p', { class: 'pista-grupo' });
  const cuerpo = el('div', { class: 'cuerpo-pregunta' });
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const segmentos = preguntas.map((_, i) => {
    const b = el('button', { type: 'button', class: 'segmento', 'aria-label': `Ir a la pregunta ${i + 1}` });
    b.addEventListener('click', () => ir(i));
    return b;
  });
  const anterior = boton('← Anterior', () => { if (actual > 0) ir(actual - 1); else app.ir('datos'); });
  const siguiente = boton('Siguiente →', continuar, 'primario');
  const vista = pantalla('cuestionario',
    el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, 'PASO 03 / TUS PREFERENCIAS'), el('h1', { class: 'titulo-pantalla' }, 'Aquí no hay respuestas incorrectas.'), el('p', { class: 'subtitulo' }, 'Toca la opción que más se parezca a ti, aunque ninguna te describa por completo.')),
    panel({ clase: 'panel-pregunta' },
      el('div', { class: 'cabecera-pregunta' }, chip, numero),
      el('div', { class: 'segmentos' }, segmentos),
      pista, cuerpo, aviso,
      el('div', { class: 'acciones pie-cuestionario' }, anterior, siguiente)));
  contenedor.append(vista);

  function marcadores() {
    const respondidas = total - preguntasFaltantes(total).length;
    numero.textContent = `Pregunta ${actual + 1} de ${total} · ${respondidas} respondidas`;
    segmentos.forEach((b, i) => {
      b.classList.toggle('hecha', Boolean(estado.respuestas[i]));
      b.classList.toggle('actual', i === actual);
      if (i === actual) b.setAttribute('aria-current', 'step'); else b.removeAttribute('aria-current');
      b.disabled = enviando;
    });
    anterior.textContent = actual === 0 ? '← Sobre ti' : '← Anterior';
    siguiente.textContent = actual < total - 1 ? 'Siguiente →' : reintento ? 'Reintentar mi resultado' : 'Descubrir mi perfil ✦';
  }

  function pintar(enfocar) {
    const p = preguntas[actual];
    const bloque = Math.floor(actual / PREGUNTAS_POR_DIMENSION);
    chip.textContent = TEMAS[bloque] ?? `Bloque ${bloque + 1}`;
    chip.dataset.bloque = String(bloque % 4);
    pista.textContent = PISTAS[bloque] ?? '';
    aviso.textContent = '';
    const titulo = el('legend', { class: 'pregunta-titulo', tabindex: '-1' }, p.pregunta);
    cuerpo.replaceChildren(el('fieldset', { class: 'pregunta', id: `bloque-${actual}` }, titulo,
      el('div', { class: 'opciones' }, ['A', 'B'].map((letra) => {
        const input = el('input', { type: 'radio', name: `pregunta-${actual}`, value: letra, checked: estado.respuestas[actual] === letra });
        // detail > 0: toque o clic. Con el teclado no se avanza solo, para poder comparar A y B.
        input.addEventListener('click', (evento) => elegir(letra, evento.detail > 0));
        return el('label', { class: 'opcion' }, input,
          el('span', { class: 'letra-opcion', 'aria-hidden': 'true' }, letra),
          el('span', { class: 'texto-opcion' }, p[letra]),
          el('span', { class: 'marca-elegida', 'aria-hidden': 'true' }, '✓ Elegida'));
      }))));
    marcadores();
    if (enfocar) {
      titulo.focus({ preventScroll: true });
      if (vista.getBoundingClientRect().top < 0) vista.scrollIntoView({ block: 'start' });
    }
  }

  function ir(nuevo, enfocar = true) {
    if (enviando) return;
    clearTimeout(temporizador);
    actual = nuevo;
    pintar(enfocar);
  }

  function elegir(letra, avanzarSolo) {
    if (enviando) return;
    estado.respuestas[actual] = letra;
    estado.resultado = null;
    aviso.textContent = '';
    guardarSesion('cuestionario');
    marcadores();
    clearTimeout(temporizador);
    if (avanzarSolo && actual < total - 1) {
      const desde = actual;
      temporizador = setTimeout(() => { if (vista.isConnected && !enviando && actual === desde) ir(desde + 1); }, AVANCE_MS);
    }
  }

  async function continuar() {
    if (enviando) return;
    if (actual < total - 1) {
      if (!estado.respuestas[actual]) {
        aviso.textContent = 'Toca una opción para continuar.';
        cuerpo.querySelector('input')?.focus();
        return;
      }
      ir(actual + 1);
      return;
    }
    const faltantes = preguntasFaltantes(total);
    if (faltantes.length) {
      ir(faltantes[0], false);
      aviso.textContent = `Todavía falta responder: ${faltantes.map((n) => n + 1).join(', ')}. Toca una opción para continuar.`;
      cuerpo.querySelector('input')?.focus();
      return;
    }
    enviar();
  }

  async function enviar() {
    clearTimeout(temporizador);
    enviando = true; marcadores();
    vista.querySelectorAll('button, input').forEach((n) => { n.disabled = true; });
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
      enviando = false; reintento = true;
      vista.querySelectorAll('button, input').forEach((n) => { n.disabled = false; });
      siguiente.removeAttribute('aria-busy');
      marcadores();
    }
  }

  pintar(false);
}
