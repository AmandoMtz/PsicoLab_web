import { guardarSesion } from '../sesion.js';
import { eliminarRegistro } from '../api.js';
import { estado, reiniciar } from '../estado.js';
import { AVISO_IA } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';
import { etiquetaCarrera } from '../carreras.js';

function panelTarjeta(resultado) {
  return panel({ clase: 'panel-tarjeta' },
    el('div', { class: 'tarjeta-marco' }, el('a', { class: 'tarjeta-enlace', href: resultado.tarjeta, target: '_blank', rel: 'noopener', 'aria-label': 'Abrir mi tarjeta en tamaño completo' },
      el('img', { src: resultado.tarjeta, alt: `Tarjeta digital del perfil ${resultado.perfil}`, width: '800', height: '1000', decoding: 'async' }))),
    el('a', { class: 'boton boton-secundario descargar', href: resultado.tarjeta, download: `PsicoLab-${resultado.perfil}.png` }, '↓ Descargar mi tarjeta'),
    el('p', { class: 'microtexto' }, `Perfil ${resultado.perfil} · Clase ${resultado.clase} de 16 · Toca la tarjeta para verla completa`));
}
function panelTrabajos(resultado) {
  return panel({ clase: 'panel-trabajos' },
    el('p', { class: 'sobrelinea' }, 'DE TUS PREFERENCIAS A LAS POSIBILIDADES'),
    el('h2', {}, '¿Dónde podrías explorar?'),
    el('p', { class: 'intro-trabajos' }, 'Tres áreas relacionadas con ', el('strong', {}, etiquetaCarrera(resultado.carrera)), ' y el perfil estimado. Tómalas como ideas para investigar.'),
    resultado.areas.map((area, i) => el('article', { class: `trabajo trabajo-${i + 1}` },
      el('span', { class: 'trabajo-numero', 'aria-hidden': 'true' }, String(i + 1).padStart(2, '0')),
      el('div', {}, el('h3', {}, area.area), el('p', {}, area.actividades)))),
    el('div', { class: 'reflexion' }, el('span', { 'aria-hidden': 'true' }, '✦'), el('div', {}, el('h3', {}, 'La siguiente pregunta es tuya.'), el('p', {}, '¿Cuál de estas actividades te da más curiosidad? Coméntala con alguien de tu carrera y descubre cómo se vive en la práctica.'))),
    el('p', { class: 'nota' }, 'Sugerencias ilustrativas: no demuestran aptitud o empleabilidad.'));
}

function seccionRegistro(resultado) {
  const zona = el('div', { class: 'registro' });

  function pintar() {
    const { registro } = resultado;
    if (!registro.guardado) {
      zona.replaceChildren(el('p', { class: 'aviso' }, registro.mensaje));
      return;
    }
    zona.replaceChildren(
      el('p', { class: 'exito' }, registro.mensaje),
      el('p', { class: 'codigo' }, `Código de registro: ${registro.id}`),
      boton('Eliminar registro de esta sesión', eliminar, 'verde'));
  }

  async function eliminar() {
    if (!window.confirm('¿Eliminar las respuestas, edad, sexo y carrera de esta sesión?')) return;
    try {
      await eliminarRegistro(resultado.registro.id);
    } catch (error) {
      pintar();
      zona.append(el('p', { class: 'aviso' }, `Error al eliminar: ${error.message}`));
      return;
    }
    estado.registroId = null;
    resultado.registro = { guardado: false, id: null, mensaje: 'Registro eliminado.' };
    guardarSesion('resultado');
    pintar();
  }

  pintar();
  return zona;
}

export function mostrarResultado(contenedor, app) {
  const resultado = estado.resultado;
  const nuevo = () => {
    if (!window.confirm('¿Comenzar de nuevo? Se limpiará el avance de esta pestaña. Un registro ya guardado no se elimina con esta acción.')) return;
    reiniciar(); app.ir('inicio');
  };
  contenedor.append(pantalla('resultado',
    el('div', { class: 'resultado-encabezado' },
      el('div', {}, el('p', { class: 'sobrelinea' }, 'PASO 04 / TU PERFIL'), el('h1', { class: 'titulo-pantalla' }, 'Una nueva forma de mirarte.'), el('p', { class: 'subtitulo' }, 'Tus respuestas dieron lugar a este perfil estimado. Explora qué te resulta familiar y qué te sorprende.')),
      el('div', { class: 'perfil-insignia' }, el('small', {}, 'TU PERFIL ESTIMADO'), el('strong', {}, resultado.perfil), el('span', {}, etiquetaCarrera(resultado.carrera)))),
    el('div', { class: 'paneles' }, panelTarjeta(resultado), panelTrabajos(resultado)),
    el('div', { class: 'resultado-cierre' }, el('div', {}, el('h2', {}, 'Tu resultado abre una conversación.'), el('p', {}, 'No define quién eres ni limita lo que puedes llegar a hacer.')),
      el('div', { class: 'acciones' }, boton('← Revisar mis respuestas', () => app.ir('cuestionario')), boton('Nuevo cuestionario', nuevo, 'marino'))),
    seccionRegistro(resultado),
    el('details', { class: 'acerca-resultado' }, el('summary', {}, 'Cómo se obtuvo este resultado'), el('p', { class: 'aviso-ia' }, AVISO_IA))));
}
