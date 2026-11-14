// Ayudas para construir la interfaz. Todo el texto se inserta como texto,
// nunca como HTML, para que ningún dato pueda inyectar código en la página.

export function el(etiqueta, atributos = {}, ...hijos) {
  const nodo = document.createElement(etiqueta);
  for (const [nombre, valor] of Object.entries(atributos)) {
    if (nombre.startsWith('on')) nodo.addEventListener(nombre.slice(2), valor);
    else if (valor === true) nodo.setAttribute(nombre, '');
    else if (valor !== false && valor != null) nodo.setAttribute(nombre, valor);
  }
  nodo.append(...hijos.flat(Infinity).filter((hijo) => hijo != null && hijo !== false));
  return nodo;
}

export function boton(texto, alPulsar, variante = 'secundario') {
  return el('button', { type: 'button', class: `boton boton-${variante}`, onclick: alPulsar }, texto);
}

// Recuadro blanco con borde gris y, opcionalmente, una franja de color arriba.
export function panel({ franja, clase } = {}, ...hijos) {
  return el('section', { class: clase ? `panel ${clase}` : 'panel' },
    franja && el('div', { class: `franja franja-${franja}` }),
    ...hijos);
}

// Tkinter ajusta una etiqueta de varias líneas al ancho de su línea más larga y
// luego la centra; en CSS ese texto ocuparía todo el ancho máximo. Se mide y se ajusta.
export function ajustarAlTexto(nodo) {
  const medir = () => {
    if (!nodo.isConnected) {
      window.removeEventListener('resize', medir);
      return;
    }
    nodo.style.width = '';
    const rango = document.createRange();
    rango.selectNodeContents(nodo);
    const anchos = Array.from(rango.getClientRects(), (linea) => linea.width);
    if (anchos.length) nodo.style.width = `${Math.ceil(Math.max(...anchos))}px`;
  };
  requestAnimationFrame(medir);
  document.fonts.ready.then(() => requestAnimationFrame(medir));
  window.addEventListener('resize', medir);
  return nodo;
}

// En Tkinter la barra de desplazamiento siempre se ve y, si todo cabe, su
// deslizador ocupa el canal completo. Se marca la zona para imitarlo con CSS.
export function vigilarDesborde(nodo) {
  const revisar = () => {
    const sinDesborde = nodo.scrollHeight <= nodo.clientHeight;
    if (nodo.classList.contains('sin-desborde') === sinDesborde) return;
    nodo.classList.toggle('sin-desborde', sinDesborde);
    nodo.style.overflowY = 'hidden'; // obliga al navegador a redibujar la barra
    void nodo.offsetHeight;
    nodo.style.overflowY = '';
  };
  const observador = new ResizeObserver(revisar);
  observador.observe(nodo);
  Array.from(nodo.children).forEach((hijo) => observador.observe(hijo));
  revisar();
  return () => observador.disconnect();
}

export function pantalla(nombre, ...hijos) {
  return el('div', { class: `pantalla p-${nombre}` }, ...hijos);
}
