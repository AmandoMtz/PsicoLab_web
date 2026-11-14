# PsicoLab 2.0 Web — instrucciones para quien continúe el proyecto (persona o IA)

Lee este archivo completo antes de tocar nada. Después lee `README.md` (describe la app de escritorio original).

## 1. Qué es y en qué estado está

PsicoLab 2.0 es una app de escritorio en Python/Tkinter (`app_psicolab.py`): consentimiento → datos generales
(edad, sexo, carrera) → 20 preguntas A/B → una red neuronal MLP (scikit-learn) predice 1 de 16 perfiles → se muestran
la tarjeta del perfil y 3 áreas de trabajo según la carrera. Las respuestas consentidas se guardan en SQLite.

Se está publicando como sitio web en **Render** para que un grupo de estudiantes la conteste el **jueves 19 de
noviembre de 2026**.

| Fase | Estado |
| --- | --- |
| 1 · API con FastAPI (`web/`) | Terminada |
| 2 · Pantallas web idénticas a las de escritorio (`web/estatico/`) | Terminada |
| 3 · Publicar en Render | **Pendiente** (ver sección 9) |

Las pruebas deben dar **59 passed**.

## 2. Reglas de trabajo (las fijó el responsable; obligatorias)

1. Trabajar por fases. Detenerse y pedir confirmación antes de cualquier decisión importante.
2. No escribir código ni crear archivos hasta que se apruebe la arquitectura de esa fase.
3. No agregar tecnologías, frameworks ni librerías porque sean populares. Antes de proponer una dependencia, indicar
   cuál es, el motivo, el problema que resuelve, la alternativa y si es realmente necesaria.
4. No cambiar el stack sin consultar.
5. No ocultar errores: mostrarlos tal cual y explicar la causa.
6. Al terminar cada fase: ejecutar las pruebas, listar los archivos creados y modificados, dar los comandos y explicar
   cómo comprobar que funciona.
7. Código modular y legible, sin duplicación ni archivos gigantes. Comentarios solo cuando sean necesarios.
8. Los cambios se entregan como **un script de PowerShell** que el responsable ejecuta (no archivos sueltos):
   - El `.ps1` va en UTF-8 **con BOM**; sin BOM, Windows PowerShell 5.1 rompe los acentos.
   - Cada archivo se escribe con una here-string literal (`@'` … `'@`) y
     `[System.IO.File]::WriteAllText(ruta, texto, UTF8 sin BOM)`, con saltos de línea LF.
   - El script empieza comprobando que se ejecuta en la carpeta del proyecto (que exista `psicolab_core.py`).
   - Antes de sobrescribir un archivo existente, compara su SHA-256 con la versión esperada o con la ya corregida.
     Si no coincide, se detiene sin modificar nada.
   - Los binarios se incrustan en base64 y se escriben con `WriteAllBytes`.
   - El responsable abre cada terminal en `C:\Users\<usuario>`: en los comandos siempre va primero el `cd`.
9. No modificar el núcleo sin consultar: `psicolab_core.py`, `storage.py`, `app_psicolab.py`, `investigacion.py`,
   `version.py`, `datos/`, `modelos/`, `assets/`.

## 3. Stack fijo y versiones

- Python **3.12** (la computadora del responsable). También funciona con 3.13.
- `scikit-learn==1.8.0` **exacto**: el modelo `modelos/MLP_12000.joblib` se guardó con esa versión. Con otra versión
  aparece `InconsistentVersionWarning` y la predicción no es confiable.
- Servidor: `fastapi==0.162.7`, `uvicorn==0.54.0` (`requirements-web.txt`, que incluye `requirements.txt`).
- Pruebas: `pytest==9.2.0`, `httpx2==2.16.0` (`requirements-dev.txt`). Se usa `httpx2` porque la versión actual de
  FastAPI marca `httpx` como obsoleto para `TestClient`.
- Frontend: HTML, CSS y JavaScript con módulos ES, **sin framework ni compilación**, servidos por el mismo FastAPI.
- Datos: SQLite mediante `storage.py`.

## 4. Estructura

```
app_psicolab.py      app de escritorio (Tkinter); referencia del diseño y del texto del consentimiento
psicolab_core.py     núcleo: preguntas, carreras, predict_ai (MLP), career_areas
storage.py           SQLite; único cambio hecho: _db() cierra siempre la conexión
investigacion.py     comandos: estado | exportar --salida X | entrenar | activar (entrenar/activar usan pandas)
version.py           VERSION='2.0', ALLOW_REAL_STORAGE=True
capturas/            capturas de escritorio a 1160×850: referencia visual obligatoria
web/
  app.py             entrada: uvicorn web.app:app · monta /api, /tarjetas (assets/) y / (estatico/) · fija los tipos MIME
  config.py          ventana de registro y carpeta de datos (variables de entorno)
  esquemas.py        modelos Pydantic de entrada y salida
  servicio.py        casos de uso; UMBRAL_OPERACION = 0.80 (igual que en escritorio)
  rutas.py           rutas HTTP
  estatico/
    index.html  favicon.svg  css/estilos.css  fuentes/ (DejaVu Sans woff2 + licencia)
    js/ main.js (navegación e historial) api.js estado.js textos.js ui.js
    js/pantallas/ inicio.js consentimiento.js datos.js cuestionario.js resultado.js
tests/
  test_core.py test_demografia.py test_v2_flow.py   (originales del proyecto)
  test_web_registro.py test_web_api.py test_web_pantallas.py
```

## 5. Ejecutar y probar (Windows, PowerShell)

```powershell
cd "<carpeta del proyecto>"
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe -m pytest -q
New-Item -ItemType Directory -Force "$env:LOCALAPPDATA\PsicoLab2Web" | Out-Null
$env:PSICOLAB_DATA_DIR = "$env:LOCALAPPDATA\PsicoLab2Web"
.\.venv\Scripts\python.exe -m uvicorn web.app:app --reload
```

Después: `http://127.0.0.1:8000/` (pantallas), `/api/salud` (debe decir `"almacenamiento":"listo"`) y `/docs` (API).
Usa una carpeta de datos distinta a la de la app de escritorio (`%LOCALAPPDATA%\PsicoLab2`).

## 6. Variables de entorno

| Variable | Uso |
| --- | --- |
| `PSICOLAB_DATA_DIR` | Carpeta de `respuestas.sqlite3`. **Debe existir**; si no existe, no se guarda nada. En Render: `/var/data` (disco persistente). |
| `PSICOLAB_GUARDAR_DESDE` | Inicio del guardado, `AAAA-MM-DDTHH:MM`, hora del centro de México (UTC−6 fijo; México no tiene horario de verano desde 2022). |
| `PSICOLAB_GUARDAR_HASTA` | Fin del guardado, mismo formato. Una fecha mal escrita detiene el arranque con un mensaje claro. |

Sin fechas no hay límite de tiempo. Valores para el 19: `2026-11-19T00:00` y `2026-11-19T18:30`.

## 7. API y reglas de negocio

- `GET /api/catalogo` → `{preguntas:[{id, pregunta, A, B}], carreras:[…]}`. Nunca se envían `pole_A`/`pole_B`.
- `POST /api/resultado` recibe `{consentimiento:true, edad:17–65, sexo:'Masculino'|'Femenino', carrera:<del catálogo>,
  respuestas:[20 × 'A'|'B'], registro_id?:UUID}` y devuelve `{clase, perfil, tarjeta, carrera, areas[3],
  registro:{guardado, id, mensaje}}`.
  - Con `registro_id` se actualiza el mismo registro ("Revisar respuestas" no duplica).
  - **Nunca** se devuelven la confianza, el umbral ni las alternativas: es una decisión del proyecto.
  - Se guarda solo si `ALLOW_REAL_STORAGE`, la hora está dentro de la ventana y `PSICOLAB_DATA_DIR` existe. Si falla,
    se informa el error en `registro.mensaje`, sin ocultarlo.
- `DELETE /api/registros/{id}` → 204. Responde 503 si no hay almacenamiento.
- `GET /api/salud` → `{estado, almacenamiento: listo|no configurado|desactivado|error: …, guardar_desde, guardar_hasta}`.

## 8. Diseño: debe ser idéntico a la app de escritorio

Lo exigió el responsable. Toda pantalla se compara con `capturas/*.png` en una ventana de **1160×850**. Hoy las
diferencias son de 1 a 2 px, por el suavizado del texto; la de consentimiento difiere porque la captura tiene un texto
anterior.

- Tkinter dibujó a **1.397 px por punto**: en `estilos.css` todo tamaño de letra es `calc(N * var(--pt))` con los
  mismos puntos que `app_psicolab.py`. Los márgenes van en px (son el `padx`/`pady` de Tkinter).
- Fuente DejaVu Sans incluida (subconjunto latino en woff2, ~21 KB por archivo). Se usa `letter-spacing` de 0.1 px en
  texto normal y de −0.09 px en negritas de 11 pt, para igualar el ancho del texto de Tkinter.
- Controles del tema *clam* copiados píxel a píxel: combobox gris con botón de flecha, barra de progreso con doble
  borde, radio azul claro de 10 px y barras de desplazamiento siempre visibles. Las barras se estilizan con
  `::-webkit-scrollbar` (solo Chrome/Edge; no uses `scrollbar-color`, porque anula esos estilos).
- `ui.ajustarAlTexto` imita el ancho de una etiqueta de varias líneas de Tkinter. `ui.vigilarDesborde` dibuja el
  deslizador lleno cuando no hay desplazamiento.
- La lista de preguntas es `display:flex` para que los márgenes no se fusionen (en Tkinter el `pady` se suma).
- El texto del consentimiento en `js/textos.js` es copia literal del de `app_psicolab.py`, y
  `tests/test_web_pantallas.py` exige que coincidan.
- Diferencias aceptadas: "Salir" → "Volver al inicio"; "Código de registro" sin "local"; en celular, una columna.

## 9. Fase 3 pendiente: Render

1. Crear un repositorio **privado** en GitHub. El `.gitignore` ya excluye `.venv`, cachés y bases `.sqlite3`.
2. Agregar `.python-version` con `3.12`.
3. Crear un Web Service:
   - Build: `pip install -r requirements-web.txt`
   - Start: `uvicorn web.app:app --host 0.0.0.0 --port $PORT`
   - Health check: `/api/salud`
   - Variables: `PSICOLAB_GUARDAR_DESDE` y `PSICOLAB_GUARDAR_HASTA` (sección 6)
4. Martes 17: probarlo en el plan Free. Sin disco no guarda nada y muestra "Modo de prueba".
5. Miércoles 18, 19:00: pasar a Starter, agregar un disco de 1 GB en `/var/data` y definir
   `PSICOLAB_DATA_DIR=/var/data`. Verificar que `/api/salud` diga `listo`.
6. Jueves 19, 18:30–19:00: desde el Shell de Render ejecutar `python investigacion.py estado` y
   `python investigacion.py exportar --salida /var/data/respuestas_19nov.csv`, y descargar el CSV (método por
   confirmar).
7. Jueves 19, 19:00: borrar el servicio, solo después de tener el CSV.

Costo: Starter US$7/mes y disco US$0.25/GB/mes, cobrados por segundo; unos US$0.24 por las 24 h.

## 10. Decisiones pendientes (las toma el responsable)

- Texto del consentimiento: el actual dice "anónima"; el README dice "seudonimizados". Además debería mencionar que los
  datos se guardan en un servidor externo. La captura `Consentimiento_2.0.png` tiene una versión anterior más precisa.
  Si se cambia, hay que cambiar web y escritorio.
- `pandas` no está en `requirements.txt`; lo necesitan `entrenar` y `activar`.
- Quién crea el repositorio de GitHub.
- Revisión visual final en la computadora del responsable.

## 11. Trampas ya encontradas

- **Windows:** Python toma los tipos MIME del registro (`.js` como `application/javascript` o incluso `text/plain`).
  `web/app.py` los fija.
- **Windows:** un archivo SQLite abierto no se puede borrar. Por eso `storage._db()` cierra cada conexión.
- `tests/test_v2_flow.py` deja `PSICOLAB_DATA_DIR` modificado en `os.environ`. En pruebas nuevas usa `monkeypatch`.
- `TestClient` solo ejecuta el *lifespan* (precarga del modelo) si se usa con `with TestClient(app) as c:`.
- Playwright en modo *headless* oculta las barras de desplazamiento. Para comparar el diseño, lánzalo con
  `ignore_default_args=['--hide-scrollbars']`.
- Los datos de participantes nunca se suben al repositorio ni se comparten: viven en `PSICOLAB_DATA_DIR`.


## 12. Actualización del 14/11/2026
El usuario autorizó mejorar la web y añadir animaciones. La capa `css/mejoras.css` reemplaza el requisito de identidad visual exacta únicamente en la web. Se preservó el núcleo y las tarjetas. Véanse `CAMBIOS_RENDER.md` y `RENDER.md` para el estado actualizado (64 pruebas, revisión visual pendiente por limitación del entorno). `render.yaml` es una prueba Free sin disco; todavía NO está desplegado. El consentimiento original sigue pendiente de aprobación. `js/sesion.js` conserva avance en la pestaña con caducidad de dos horas. El actualizador PowerShell valida todos los archivos antes de escribir y acepta originales o ya actualizados.


## 13. Rediseño web solicitado por el usuario (14/11/2026)
El usuario pidió una web más intuitiva y personalizada tras verla publicada en Render. La web usa ahora cuatro bloques de cinco preguntas, selección visual de carrera y nueva composición de inicio/resultado. Esto sustituye en la web la lista de 20 preguntas en una sola pantalla y el requisito visual de escritorio. No cambia la API ni el núcleo. Véase REDISENO_WEB.md para alcance y validación; el rediseño todavía no se ha publicado.
