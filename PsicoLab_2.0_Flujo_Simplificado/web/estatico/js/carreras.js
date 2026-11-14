// Solo cambia cómo se muestran las carreras. El valor que se envía a la API
// y que usa el núcleo (career_areas) sigue siendo el del catálogo, sin tocar.
export const FACULTAD = 'Facultad de Derecho y Ciencias Sociales (FADYCS)';

const CARRERAS = [
  { claves: ['comunicacion'], etiqueta: 'Licenciatura en Ciencias de la Comunicación', icono: '✎' },
  { claves: ['derecho'], etiqueta: 'Licenciatura en Derecho', icono: '§' },
  { claves: ['economia', 'finanzas'], etiqueta: 'Licenciatura en Economía y Finanzas', icono: '$' },
  { claves: ['turismo', 'turistic'], etiqueta: 'Licenciatura en Gestión y Desarrollo Turístico', icono: '✈' },
  { claves: ['ingles'], etiqueta: 'Licenciatura en Idioma Inglés', icono: 'Aa' },
  { claves: ['psicologia'], etiqueta: 'Licenciatura en Psicología', icono: 'Ψ' },
];

const normalizar = (texto) => texto.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
const buscar = (valor) => {
  const n = normalizar(String(valor));
  return CARRERAS.find((c) => c.claves.some((clave) => n.includes(clave)));
};

export const etiquetaCarrera = (valor) => buscar(valor)?.etiqueta ?? valor;
export const iconoCarrera = (valor) => buscar(valor)?.icono ?? '•';

// Orden alfabético de la lista oficial; lo desconocido queda al final.
export function ordenarCarreras(valores) {
  const posicion = (valor) => {
    const c = buscar(valor);
    return c ? CARRERAS.indexOf(c) : CARRERAS.length;
  };
  return [...valores].sort((a, b) => posicion(a) - posicion(b));
}
