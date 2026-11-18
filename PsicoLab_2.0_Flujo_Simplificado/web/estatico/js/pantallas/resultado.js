import { estado, reiniciar } from '../estado.js';
import { AVISO_IA } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';
import { etiquetaCarrera } from '../carreras.js';

function panelTarjeta(resultado) {
  return panel({ clase: 'panel-tarjeta' },
    el('div', { class: 'tarjeta-marco' }, el('a', { class: 'tarjeta-enlace', href: resultado.tarjeta, target: '_blank', rel: 'noopener', 'aria-label': 'Abrir mi tarjeta en tamaño completo' },
      el('img', { src: resultado.tarjeta, alt: `Tarjeta digital del perfil ${resultado.perfil}`, width: '800', height: '1000', decoding: 'async' }))),
    el('a', { class: 'boton boton-secundario descargar', href: resultado.tarjeta, download: `PsicoLab-${resultado.perfil}.png` }, '↓ Descargar mi tarjeta'));
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

export function mostrarResultado(contenedor, app) {
  const resultado = estado.resultado;
  const nuevo = () => {
    if (!window.confirm('¿Comenzar de nuevo? Se limpiará el avance de esta pestaña. Un registro ya guardado no se elimina con esta acción.')) return;
    reiniciar(); app.ir('inicio');
  };
  contenedor.append(pantalla('resultado',
    el('div', { class: 'resultado-encabezado' },
      el('div', {}, el('p', { class: 'sobrelinea' }, 'PASO 4 / TU PERFIL'), el('h1', { class: 'titulo-pantalla' }, 'Una nueva forma de mirarte.'), el('p', { class: 'subtitulo' }, 'Tus respuestas dieron lugar a este perfil estimado. Explora qué te resulta familiar y qué te sorprende.')),
      el('div', { class: 'perfil-insignia' }, el('small', {}, 'TU PERFIL ESTIMADO'), el('strong', {}, resultado.perfil), el('span', {}, etiquetaCarrera(resultado.carrera)))),
    el('div', { class: 'paneles' }, panelTarjeta(resultado), panelTrabajos(resultado)),
    el('div', { class: 'resultado-cierre' }, el('div', {}, el('h2', {}, 'Tu resultado'), el('p', {}, AVISO_IA)),
      el('div', { class: 'acciones' }, boton('¡Ahora, un reto! →', () => app.ir('retos_intro'), 'primario'), boton('← Revisar mis respuestas', () => app.ir('cuestionario')), boton('Nuevo cuestionario', nuevo, 'marino'))),
    !resultado.registro.guardado ? el('p', { class: 'aviso', role: 'status' }, 'Tus respuestas no se guardaron. Revisa tus respuestas para volver a intentarlo antes de iniciar los retos.') : null));
}
