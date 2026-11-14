import { guardarSesion } from '../sesion.js';
import { calcularResultado } from '../api.js';
import { estado, preguntasFaltantes } from '../estado.js';
import { DIMENSIONES, PREGUNTAS_POR_DIMENSION } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';

function encabezadoDimension(numero) {
  const { titulo, color } = DIMENSIONES[numero];
  return el('p', { class: 'dimension', style: `color: ${color}` }, `DIMENSIÓN ${numero + 1} · ${titulo}`);
}

function bloquePregunta(pregunta, indice, alResponder) {
  const numero = String(indice + 1).padStart(2, '0');
  const idTexto = `pregunta-${indice}`;
  return el('div', { class: 'pregunta', role: 'radiogroup', 'aria-labelledby': idTexto },
    el('p', { class: 'pregunta-texto', id: idTexto }, `${numero}. ${pregunta.pregunta} *`),
    ['A', 'B'].map((letra) => el('label', { class: 'opcion' },
      el('input', {
        type: 'radio',
        name: idTexto,
        value: letra,
        checked: estado.respuestas[indice] === letra,
        onchange: () => alResponder(letra),
      }),
      el('span', {}, `${letra}) ${pregunta[letra]}`))));
}

export function mostrarCuestionario(contenedor, app) {
  const { preguntas } = app.catalogo;
  const total = preguntas.length;
  const barra = el('div', { class: 'progreso-barra' });
  const contador = el('p', { class: 'progreso-texto', role: 'status', 'aria-live': 'polite' });
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const verResultado = boton('Ver mi resultado', () => enviar(), 'pendiente');
  const bloques = preguntas.map((pregunta, i) => bloquePregunta(pregunta, i, (letra) => responder(i, letra)));

  function actualizar() {
    const respondidas = total - preguntasFaltantes(total).length;
    barra.style.width = `${(100 * respondidas) / total}%`;
    barra.parentElement?.setAttribute('aria-valuenow', String(respondidas));
    bloques.forEach((bloque, i) => bloque.classList.toggle('respondida', Boolean(estado.respuestas[i])));
    contador.textContent = `${respondidas} de ${total} preguntas respondidas`;
    verResultado.className = `boton boton-${respondidas === total ? 'primario' : 'pendiente'}`;
  }

  function responder(indice, letra) {
    estado.respuestas[indice] = letra;
    estado.resultado = null;
    aviso.textContent = '';
    actualizar();
  }

  async function enviar() {
    const faltantes = preguntasFaltantes(total);
    if (faltantes.length) {
      // Igual que en escritorio: no se calcula una predicción parcial y se
      // lleva al participante al primer reactivo sin responder.
      aviso.textContent = `Faltan las preguntas: ${faltantes.map((i) => i + 1).join(', ')}`;
      bloques[faltantes[0]].scrollIntoView({ block: 'start' });
      bloques[faltantes[0]].querySelector('input').focus({ preventScroll: true });
      return;
    }
    if (verResultado.disabled) return;
    verResultado.disabled = true;
    verResultado.textContent = 'Calculando tu perfil…';
    verResultado.setAttribute('aria-busy', 'true');
    bloques.forEach((b) => b.querySelectorAll('input').forEach((n) => n.disabled = true));
    // Mantener el mismo ID si se reintenta tras una interrupción de red.
    estado.registroId ||= crypto.randomUUID();
    guardarSesion('cuestionario');
    try {
      const resultado = await calcularResultado({
        consentimiento: true,
        edad: Number(estado.edad),
        sexo: estado.sexo,
        carrera: estado.carrera,
        respuestas: preguntas.map((_, i) => estado.respuestas[i]),
        registro_id: estado.registroId,
      });
      if (!verResultado.isConnected) return;
      estado.resultado = resultado;
      if (estado.resultado.registro.guardado) estado.registroId = estado.resultado.registro.id;
      app.ir('resultado');
    } catch (error) {
      aviso.textContent = error.message;
      verResultado.disabled = false;
      verResultado.textContent = 'Ver mi resultado';
      verResultado.removeAttribute('aria-busy');
      bloques.forEach((b) => b.querySelectorAll('input').forEach((n) => n.disabled = false));
    }
  }

  contenedor.append(pantalla('cuestionario',
    el('h1', { class: 'titulo-pantalla' }, 'Cuestionario de preferencias'),
    el('p', { class: 'subtitulo' },
      `${estado.edad} años · ${estado.sexo} · ${estado.carrera}  |  Todas las preguntas son obligatorias.`),
    panel({},
      el('div', { class: 'desplazable lista-preguntas' }, bloques.map((bloque, i) => [
        i % PREGUNTAS_POR_DIMENSION === 0 && encabezadoDimension(i / PREGUNTAS_POR_DIMENSION),
        bloque,
        el('div', { class: 'separador' }),
      ])),
      el('div', { class: 'pie-cuestionario' },
        el('div', { class: 'progreso', role: 'progressbar', 'aria-label': 'Preguntas respondidas', 'aria-valuemin': '0', 'aria-valuemax': String(total), 'aria-valuenow': '0' }, barra),
        contador,
        aviso,
        el('div', { class: 'acciones' },
          boton('← Datos generales', () => app.ir('datos')),
          verResultado)))));
  actualizar();
}
