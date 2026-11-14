# Cambios para Render

- Animaciones breves, tarjetas redondeadas, respuestas resaltadas y mejoras de contraste y uso táctil; se respeta movimiento reducido.
- Progreso accesible y enfoque en el primer reactivo pendiente.
- Recuperación en sessionStorage con caducidad de dos horas; reinicio limpia el borrador. No localStorage.
- ID antes del envío para reintentar sin duplicar. Una respuesta tardía no navega a otra pantalla si ya se abandonó el cuestionario.
- Liberación de ResizeObserver al cambiar de pantalla.
- Compresión HTTP, caché de imágenes/fuentes y no-store para API. No se midió una mejora porcentual de rendimiento.
- Python 3.12, Blueprint gratuito, ventana del 19/11 y límite de hilos numéricos para el servidor.
- pandas se agrega exclusivamente a requirements-modelo.txt para investigación local; no al servidor web.
- Guía de exportación con SSH/SFTP; no se exponen registros por una ruta pública.

## Validación realizada
Original: 59 passed. Actualizada: 64 passed; una advertencia externa de deprecación de anyio/pytest (CallSpec2). Modelo scikit-learn 1.8.0, Python 3.12.14.
Comprobación JavaScript con Node: recuperación, ID, caducidad, JSON corrupto, reinicio y almacenamiento bloqueado correctos. Sintaxis de todos los módulos comprobada.
La prueba visual no pudo completarse: el Chromium local falló con `socket() failed: Operation not permitted (1)` y el navegador remoto no pudo conectar al servidor local. No se afirma validación visual de escritorio/celular ni carga concurrente.
El actualizador se verificó reconstruyendo sus contenidos y hashes; no se ejecutó en PowerShell 5.1 porque ese intérprete no está disponible aquí.

## Pendiente externo
Conectar GitHub y Render, publicar y comprobar la URL real. Seleccionar disco/plan de pago para guardar. Revisar y aprobar el consentimiento con el responsable antes de recoger respuestas. No se modificaron núcleo, modelo, datos, tarjetas, app de escritorio ni texto original de consentimiento.

## Archivos creados o modificados
- `.gitignore`
- `.python-version`
- `README.md`
- `RENDER.md`
- `render.yaml`
- `requirements-modelo.txt`
- `tests/test_web_despliegue.py`
- `web/app.py`
- `web/estatico/css/mejoras.css`
- `web/estatico/index.html`
- `web/estatico/js/main.js`
- `web/estatico/js/pantallas/cuestionario.js`
- `web/estatico/js/pantallas/resultado.js`
- `web/estatico/js/sesion.js`
- `web/estatico/js/ui.js`
- `CAMBIOS_RENDER.md`
- `ACTUALIZAR_PSICOLAB.ps1`
- `AGENTS.md` (estado de continuidad)
