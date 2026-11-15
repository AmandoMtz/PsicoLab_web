# Rediseño web de PsicoLab — 14/11/2026

## Qué cambia
- Inicio con composición de tarjetas originales, explicación del recorrido y botón de inicio destacado.
- Cabecera compacta, ancho de lectura limitado, tipografía de sistema y paleta amarillo/lila/rosa/menta.
- Indicador de cuatro pasos: Tu decisión, Sobre ti, Tus preferencias y Tu perfil.
- Selección de carrera mediante tarjetas; no se añaden datos personales al formulario.
- Cuestionario organizado en cuatro bloques de cinco preguntas con progreso global, validación, navegación y recuperación del avance.
- Resultado con el perfil y la carrera destacados, tarjeta descargable y tres áreas profesionales con texto de reflexión.
- Movimiento reducido, focos visibles y diseño adaptable a pantallas pequeñas.

## Qué se conserva
Modelo, puntuación, 20 preguntas, opciones A/B, catálogo de carreras, las tarjetas originales, SQLite, ventana de guardado y texto del consentimiento. No se añadieron dependencias al servidor ni al navegador. El consentimiento sigue pendiente de revisión institucional.

## Verificación
- 64 pruebas Python aprobadas. Advertencia externa de deprecación de anyio/pytest (CallSpec2).
- Sintaxis de todos los módulos JavaScript comprobada con Node.
- Prueba de interfaz en DOM simulado (happy-dom, solo herramienta temporal de pruebas): consentimiento/rechazo, campos requeridos, los cuatro bloques, navegación atrás, preservación de respuestas, envío de las 20 respuestas en orden, error de red/reintento con el mismo ID, resultado y enlace de descarga.
- Revisión estática de inicio y resultado mediante render HTML/PDF. No sustituye una prueba de navegador real: Chromium está bloqueado por el entorno (socket Operation not permitted). Falta comprobar visualmente en Chrome/Edge y celular tras aplicar.
- Actualizador PowerShell: contenido embebido y SHA-256 comprobados; PowerShell no está disponible aquí para ejecutarlo.

## Cómo aplicar desde Windows
1. Descarga Actualizar_PsicoLab_Diseno.ps1 y colócalo dentro de la carpeta que contiene psicolab_core.py.
2. En PowerShell:

```powershell
cd "C:\Users\elnoo\Downloads\PsicoLab_web\PsicoLab_2.0_Flujo_Simplificado"
.\Actualizar_PsicoLab_Diseno.ps1
```

El script comprueba TODOS los archivos antes de escribir. Acepta la versión descargada de GitHub y la ya actualizada, incluidas terminaciones CRLF equivalentes. Si detecta cambios ajenos, se detiene sin sobrescribirlos.
3. En VS Code abre Control de código fuente, revisa los cambios, escribe “Rediseño de PsicoLab y cuestionario por bloques”, confirma el commit y sincroniza con GitHub.
4. Si Render tiene despliegue automático, espera al nuevo despliegue. Si no, usa Manual Deploy → Deploy latest commit.
5. Abre el sitio, recarga con Ctrl+F5 y prueba consentimiento → datos → 4 bloques → resultado. En celular revisa que los controles sean visibles, que no exista desplazamiento horizontal y que puedas volver a cambiar respuestas.

La actualización no se ha subido a GitHub ni desplegado desde esta entrega: falta una sesión GitHub autorizada para escritura.

## Ajustes posteriores — 14/11/2026
- Tarjeta del resultado más grande (480 px en escritorio, hasta 520 px en celular) y enlace para verla a tamaño completo.
- Carreras con los nombres oficiales de la Facultad de Derecho y Ciencias Sociales (FADYCS), solo como etiqueta; el valor enviado a la API no cambia. Selección marcada en azul marino.
- Cuestionario de una pregunta por pantalla: opciones grandes, respuesta elegida muy marcada ("Elegida" + letra amarilla), avance automático, barra de 20 segmentos y botón final "Descubrir mi perfil".
- Archivos: `js/carreras.js` (nuevo), `js/pantallas/cuestionario.js`, `datos.js`, `resultado.js`, `css/estilos.css`, `css/mejoras.css`.
- Verificación: sintaxis con Node, prueba de interfaz en DOM simulado (avance automático, sin avance con teclado, aviso si falta responder, vuelta atrás conserva la respuesta, envío de las 20 respuestas) y capturas en Chrome de escritorio y celular. Falta volver a ejecutar `pytest` en tu equipo.

## Ajustes — 15/11/2026
- El logotipo PsicoLab regresa al inicio; las dos tarjetas de ejemplo y los tres pasos del inicio tienen animación al pasar el ratón.
- Letra más grande en las preguntas y tarjeta del resultado de 600 px en escritorio, para que se pueda leer sin esfuerzo.
- Archivos: `index.html`, `js/main.js`, `js/pantallas/datos.js`, `css/estilos.css`, `css/mejoras.css`.
- Se quitó la barra de pasos superior para dar más espacio al contenido.
