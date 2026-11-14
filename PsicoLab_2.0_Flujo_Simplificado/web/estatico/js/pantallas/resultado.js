import { guardarSesion } from '../sesion.js';
import { eliminarRegistro } from '../api.js';
import { estado, reiniciar } from '../estado.js';
import { AVISO_IA } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';

function panelTarjeta(resultado) {
  return panel({ franja: 'amarilla', clase: 'panel-tarjeta' },
    el('img', { src: resultado.tarjeta, alt: `Tarjeta digital del perfil ${resultado.perfil}`, width: '800', height: '1000' }),
    el('p', { class: 'nombre' }, `Tarjeta digital: ${resultado.perfil}`),
    el('p', { class: 'identificador' }, `Identificador predicho: ${resultado.clase}`));
}

function panelTrabajos(resultado) {
  return panel({ franja: 'rosa', clase: 'panel-trabajos' },
    el('p', { class: 'etiqueta' }, 'TRES OPCIONES DE TRABAJO PARA EXPLORAR'),
    el('h2', {}, `Basadas en tu carrera: ${resultado.carrera}`),
    resultado.areas.map((area, i) => el('div', { class: `trabajo trabajo-${i + 1}` },
      el('h3', {}, `${i + 1}. ${area.area}`),
      el('p', {}, area.actividades))),
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
  const clase = String(resultado.clase).padStart(2, '0');
  const nuevo = () => { reiniciar(); app.ir('inicio'); };
  const vista = pantalla('resultado',
    el('h1', { class: 'titulo-pantalla' }, 'Tu resultado de inteligencia artificial'),
    el('p', { class: 'subtitulo' }, `Clase ${clase} de 16 · ${resultado.perfil} · Carrera: ${resultado.carrera}`),
    el('div', { class: 'paneles' }, panelTarjeta(resultado), panelTrabajos(resultado)),
    el('div', { class: 'acciones' },
      boton('← Revisar respuestas', () => app.ir('cuestionario')),
      boton('Nuevo cuestionario', nuevo, 'naranja')),
    seccionRegistro(resultado),
    el('p', { class: 'aviso-ia' }, AVISO_IA));
  vista.classList.add('desplazable');
  contenedor.append(vista);
}
