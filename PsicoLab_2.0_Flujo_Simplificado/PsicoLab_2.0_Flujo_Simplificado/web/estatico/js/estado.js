// Datos de la sesión del participante. Viven solo en memoria: al cerrar o
// recargar la pestaña se pierden, igual que al cerrar la app de escritorio.

export const EDAD_MINIMA = 17;
export const EDAD_MAXIMA = 65;
export const SEXOS = ['Masculino', 'Femenino'];

function inicial() {
  return {
    consentimiento: false,
    edad: '',
    sexo: '',
    carrera: '',
    respuestas: {}, // índice de pregunta -> 'A' o 'B'
    registroId: null,
    resultado: null,
    retos: null,
  };
}

export const estado = inicial();

export function reiniciar() {
  Object.assign(estado, inicial());
}

export function datosCompletos(carreras) {
  const edad = Number(estado.edad);
  return Number.isInteger(edad) && edad >= EDAD_MINIMA && edad <= EDAD_MAXIMA
    && SEXOS.includes(estado.sexo)
    && carreras.includes(estado.carrera);
}

export function preguntasFaltantes(total) {
  return Array.from({ length: total }, (_, i) => i).filter((i) => !estado.respuestas[i]);
}
