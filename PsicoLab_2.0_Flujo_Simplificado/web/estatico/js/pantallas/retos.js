import { estado, reiniciar } from '../estado.js';
import { iniciarRetos, finalizarRetos } from '../api.js';
import { guardarSesion } from '../sesion.js';
import { boton, el, panel, pantalla } from '../ui.js';

const AVISO = 'Modelo experimental entrenado con datos sintéticos. Las coincidencias no demuestran que pueda anticipar decisiones reales ni constituyen una evaluación psicológica.';

export function mostrarIntroRetos(contenedor, app) {
  let ocupado = false;
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const comenzar = boton('Comenzar los 3 retos →', iniciar, 'primario');
  const vista = pantalla('retos-intro',
    panel({ clase: 'intro-retos' },
      el('p', { class: 'sobrelinea' }, 'SEGUNDA ETAPA / DESAFÍA AL ALGORITMO'),
      el('h1', { class: 'titulo-pantalla' }, '¡Ahora, un reto!'),
      el('h2', {}, '¿Puede un algoritmo adivinar tus decisiones?'),
      el('p', { class: 'subtitulo' }, 'Explora tres situaciones y elige qué harías tú. Al terminar, descubrirás cuántas elecciones coincidieron con las del algoritmo.'),
      el('div', { class: 'retos-pasos' },
        el('p', {}, el('strong', {}, '01'), ' El algoritmo fija sus predicciones.'),
        el('p', {}, el('strong', {}, '02'), ' Tú eliges entre A, B y C.'),
        el('p', {}, el('strong', {}, '03'), ' Comparamos las tres decisiones.')),
      el('p', { class: 'nota' }, 'Para esta etapa se utilizan tus 20 respuestas, edad, género de nacimiento y carrera, junto con cuatro puntuaciones del cuestionario.'),
      el('p', { class: 'nota' }, AVISO), aviso,
      el('div', { class: 'acciones' }, boton('← Mi perfil', () => app.ir('resultado')), comenzar)));
  contenedor.append(vista);
  if (!estado.resultado?.registro.guardado) {
    comenzar.disabled = true;
    aviso.textContent = 'Primero necesitamos guardar tu cuestionario. Vuelve a tu perfil y selecciona «Revisar mis respuestas» para intentarlo nuevamente.';
  }
  async function iniciar() {
    if (ocupado) return;
    ocupado = true; comenzar.disabled = true;
    comenzar.textContent = 'Preparando los retos…'; aviso.textContent = '';
    try {
      const datos = await iniciarRetos(estado.resultado.registro.id);
      if (!vista.isConnected) return;
      const anterior = estado.retos;
      const decisiones = anterior?.reto_id === datos.reto_id && Array.isArray(anterior.decisiones)
        ? anterior.decisiones.slice(0, 3) : [];
      estado.retos = { ...datos, decisiones };
      guardarSesion('retos_intro');
      app.ir(datos.completado ? 'retos_resultado' : 'retos');
    } catch (error) {
      if (!vista.isConnected) return;
      aviso.textContent = error.message;
      comenzar.textContent = 'Reintentar los retos →'; comenzar.disabled = false; ocupado = false;
    }
  }
}

export function mostrarReto(contenedor, app) {
  const sesion = estado.retos;
  let actual = Math.min(sesion.decisiones.length, 2);
  let ocupado = false;
  const vista = pantalla('retos');
  contenedor.append(vista);
  function pintar() {
    const reto = sesion.retos[actual];
    const aviso = el('p', { class: 'aviso', role: 'alert' });
    const avanzar = boton(actual === 2 ? 'Descubrir las coincidencias ✦' : 'Siguiente reto →', siguiente, 'primario');
    const opciones = ['A', 'B', 'C'].map((letra, i) => {
      const input = el('input', { type: 'radio', name: 'decision-reto', value: letra, checked: sesion.decisiones[actual] === letra });
      input.addEventListener('change', () => {
        if (ocupado) return;
        sesion.decisiones[actual] = letra;
        guardarSesion('retos'); aviso.textContent = '';
      });
      return el('label', { class: 'opcion' }, input,
        el('span', { class: 'letra-opcion', 'aria-hidden': 'true' }, letra),
        el('span', { class: 'texto-opcion' }, reto.opciones[i]),
        el('span', { class: 'marca-elegida', 'aria-hidden': 'true' }, '✓ Elegida'));
    });
    vista.replaceChildren(
      el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, `RETO ${actual + 1} DE 3`),
        el('h1', { class: 'titulo-pantalla', tabindex: '-1' }, reto.titulo),
        el('p', { class: 'subtitulo' }, '¿Qué harías tú? La elección del algoritmo ya está guardada.')),
      panel({ clase: 'panel-pregunta panel-reto' },
        el('div', { class: 'avance-retos', 'aria-label': `Reto ${actual + 1} de 3` },
          [0, 1, 2].map(i => el('span', { class: i <= actual ? 'activo' : '' }))),
        el('fieldset', { class: 'pregunta' }, el('legend', { class: 'pregunta-titulo' }, reto.situacion),
          el('div', { class: 'opciones' }, opciones)), aviso,
        el('div', { class: 'acciones' }, boton('← Mi perfil', () => app.ir('resultado')), avanzar)));
    vista.querySelector('h1')?.focus({ preventScroll: true });
    async function siguiente() {
      if (ocupado) return;
      if (!['A', 'B', 'C'].includes(sesion.decisiones[actual])) {
        aviso.textContent = 'Elige una opción para continuar.'; return;
      }
      if (actual < 2) { actual++; pintar(); window.scrollTo(0, 0); return; }
      ocupado = true;
      vista.querySelectorAll('button,input').forEach(n => { n.disabled = true; });
      avanzar.textContent = 'Comparando tus decisiones…';
      try {
        const resultado = await finalizarRetos(sesion.reto_id, sesion.decisiones);
        if (!vista.isConnected) return;
        sesion.resultado = resultado; sesion.completado = true;
        guardarSesion('retos_resultado'); app.ir('retos_resultado');
      } catch (error) {
        if (!vista.isConnected) return;
        ocupado = false; aviso.textContent = error.message;
        vista.querySelectorAll('button,input').forEach(n => { n.disabled = false; });
        avanzar.textContent = 'Reintentar comparación';
      }
    }
  }
  pintar();
}

export function mostrarResultadoRetos(contenedor, app) {
  const sesion = estado.retos;
  const resultado = sesion.resultado;
  const texto = (i, letra) => `${letra}. ${sesion.retos[i].opciones['ABC'.indexOf(letra)]}`;
  const nuevo = () => {
    if (!window.confirm('¿Comenzar un nuevo cuestionario?')) return;
    reiniciar(); app.ir('inicio');
  };
  contenedor.append(pantalla('retos-resultado',
    el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, 'TUS DECISIONES / EL ALGORITMO'),
      el('h1', { class: 'titulo-pantalla' }, '¿Cuántas decisiones predijo?')),
    el('div', { class: 'marcador-retos', role: 'status' }, el('strong', {}, `${resultado.total} de 3`), el('span', {}, 'coincidencias')),
    el('div', { class: 'comparaciones-retos' }, sesion.retos.map((reto, i) => panel({ clase: 'comparacion-reto' },
      el('span', { class: `estado-reto ${resultado.coincidencias[i] ? 'coincide' : ''}` }, resultado.coincidencias[i] ? 'Coincidió' : 'No coincidió'),
      el('h2', {}, `${i + 1}. ${reto.titulo}`),
      el('p', {}, el('strong', {}, 'Predicción del algoritmo: '), texto(i, resultado.predicciones[i])),
      el('p', {}, el('strong', {}, 'Tu elección: '), texto(i, resultado.decisiones[i]))))),
    el('p', { class: 'aviso-suave' }, AVISO),
    el('div', { class: 'acciones' }, boton('← Mi perfil', () => app.ir('resultado')), boton('Nuevo cuestionario', nuevo, 'marino'))));
}
