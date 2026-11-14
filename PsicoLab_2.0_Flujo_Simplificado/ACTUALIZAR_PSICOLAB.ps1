# Actualizador de PsicoLab. Ejecutar dentro de la carpeta del proyecto.
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath '.\psicolab_core.py')) { throw 'Abre PowerShell en la carpeta que contiene psicolab_core.py.' }
$Raiz = (Get-Location).Path
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Archivos = @(
@{ Ruta = '.gitignore'; Original = '74AD7BF1D53C5C344ED5319A4BFDFB2548899BFCA0D8CF1FF109B5D86807B3ED'; Nuevo = '3B626A11BAB277AF459F8DC40BF48C4015F120AA8CD1C7955CC7124744ACD996'; Contenido = @'
# Entorno y cachés de Python
.venv/
__pycache__/
*.pyc
.pytest_cache/

# Datos de participantes: nunca se suben al repositorio
*.sqlite3
*.sqlite3-*
respuestas_*.csv
exportaciones/
.env
.env.*
*.pem
*.key
.playwright/

'@
}
@{ Ruta = '.python-version'; Original = ''; Nuevo = '7B55F8E67B5623C4BEF3FA691288DA9437D79D3ABA156DE48D481DB32AC7D16D'; Contenido = @'
3.12
'@
}
@{ Ruta = 'AGENTS.md'; Original = '23702B73B34E881AB5A0FE924F393FA5A7A254B910F7927E64FD87DC555C3E32'; Nuevo = '25B980D4A09DEEDDC2394D52069ACF64C1F96C97BC8DA25391BD93CAA75BC47A'; Contenido = @'
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
'@
}
@{ Ruta = 'CAMBIOS_RENDER.md'; Original = ''; Nuevo = 'B9E6C0ABB23EF26F410665D096EC58670B4771E6A3442CD65129D31F4C58B445'; Contenido = @'
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
'@
}
@{ Ruta = 'README.md'; Original = '9940323FCCF2B0B23FD4FDF0546AD85BE5D135EFD03C1C59F28E8BEA89A0F0C4'; Nuevo = '750A4B03FD762555999547FDF344ECD0EDE6376015DE2114CC1F6249F87E7926'; Contenido = @'
> **Versión web preparada para Render (14/11/2026):** consulta `RENDER.md` para publicar, activar el disco y exportar respuestas. `CAMBIOS_RENDER.md` describe las mejoras y sus pruebas. Este ZIP ya incluye los cambios; el script `ACTUALIZAR_PSICOLAB.ps1` sirve para actualizar una copia anterior sin sobrescribir cambios desconocidos.

# PsicoLab 2.0 · Inicio, consentimiento, datos generales y predicción IA

Aplicación de escritorio en **Python/Tkinter**, con tarjetas digitales originales, modelo MLP de 20 entradas entrenado sobre 12,000 simulaciones y validación cruzada de 5 folds. **Únicamente se ha modificado PsicoLab 2.0**.

## Instalación

Necesitas Python 3.11 o posterior, con Tkinter. Descomprime el ZIP y en Windows ejecuta `iniciar_windows.bat`; alternativamente:

```bash
python -m pip install -r requirements.txt
python app_psicolab.py
```

## Recorrido del participante

1. **Pantalla de inicio:** muestra la pregunta **«¿Puede un algoritmo conocerte?»**, una explicación breve y el botón Comenzar.
2. **Consentimiento informado:** permite aceptar expresamente o rechazar la participación. Sin consentimiento no se abre el cuestionario. El texto explica qué se almacena, cómo se utiliza y sus límites de privacidad.
3. **Datos generales obligatorios:** edad seleccionable entre **17 y 65** años; sexo **Masculino/Femenino**; licenciatura **Derecho, Comunicación, Turismo, Psicología, Inglés o Economía y Finanzas**.
4. **Cuestionario:** los **20 reactivos A/B en una sola página desplazable verticalmente**. Ninguno puede quedar vacío. El botón fijo **Ver mi resultado** aparece azul cuando se contestan los 20. Ante respuestas incompletas, indica cuáles faltan y no calcula una predicción parcial.
5. **Resultado:** muestra exclusivamente la **clase predicha 1–16, las letras del perfil, su tarjeta digital original y exactamente tres áreas de trabajo para explorar** asociadas a la licenciatura y al perfil predicho. No muestra otras clases estimadas ni la tabla de umbrales.

El botón **Nuevo cuestionario** reinicia respuestas, datos generales y consentimiento y devuelve a la primera pantalla.

## Red neuronal, confianza y umbral

- **Entradas de IA:** solamente R01–R20, con `A=0` y `B=1`.
- **Edad, sexo y carrera:** **NO forman parte de las entradas del modelo**, y no modifican el perfil predicho. La carrera solo filtra las tres sugerencias laborales.
- **Modelo:** MLP (`20→64→32→16`) entrenado con 12,000 respuestas sintéticas etiquetadas, con evaluación cruzada estratificada y agrupada por patrones duplicados de 5 folds.
- **Resultado principal:** `psicolab_core.predict_ai` (salida neuronal) sin ejecutar un algoritmo de puntuación para asignar el perfil.
- **Presentación:** la visualización de **confianza de IA y umbral está desactivada mediante comentarios en `app_psicolab.py`, dentro del método `result`**. El cálculo de `predict_proba` se conserva internamente, con umbral fijo experimental de 80 %, pero **ni el porcentaje ni el umbral se muestran**.
- Los valores de confianza *softmax* no son probabilidades validadas de personalidad. La exactitud con simulaciones no demuestra validación psicométrica.

## Registro y privacidad — solo PsicoLab 2.0

Si el estudiante acepta el consentimiento, se guarda localmente en SQLite: identificador aleatorio, edad, sexo, carrera, 20 respuestas A/B y perfil **predicho por la IA**. No se solicitan nombres o correos. **Los datos son seudonimizados, no irreversiblemente anónimos**, y la combinación de variables puede permitir reidentificación indirecta. Antes del uso institucional deben definirse responsable del tratamiento, base jurídica, plazo de conservación, medidas de seguridad y canales para revocar consentimiento y solicitar eliminación.

La base se ubica fuera de la carpeta del programa: `%LOCALAPPDATA%\PsicoLab2\respuestas.sqlite3` en Windows; `~/Library/Application Support/PsicoLab2` en macOS, `~/.local/share/PsicoLab2` en Linux. Puede configurarse `PSICOLAB_DATA_DIR` para cambiar la ubicación. No uses el ZIP del proyecto para recopilar o difundir registros personales.

Se conserva la opción **Eliminar registro de esta sesión** desde el resultado. La migración de versiones anteriores añade columnas `edad` y `sexo` sin borrar registros existentes; sus valores pueden quedar vacíos en registros antiguos. No se modifica la regla de reentrenamiento supervisado existente: las nuevas respuestas pueden usarse para crear **modelos candidatos**, no se incorporan automáticamente al modelo activo.

**Advertencia:** las etiquetas de participantes reales son predicciones de la propia IA; reentrenar con ellas no demuestra fiabilidad psicológica y puede reforzar errores existentes. Para investigación empírica hacen falta criterios de validación independientes.

## Herramientas del investigador

```bash
python investigacion.py estado
python investigacion.py exportar --salida registros_consensuados.csv
python investigacion.py entrenar
python investigacion.py activar --id ID_CANDIDATO --confirmar
```

La exportación contiene también edad y sexo, debe protegerse y no difundirse sin autorización. Las operaciones con `joblib` solo deben cargar modelos de origen confiable.

## Archivos

- `app_psicolab.py`: interfaz y método `result` con los porcentajes comentados.
- `psicolab_core.py`: modelo MLP y selección de tres áreas laborales.
- `storage.py`: SQLite y migración de campos edad/sexo.
- `investigacion.py`: exportación y reentrenamiento supervisado.
- `assets/`: las 16 tarjetas originales asignadas por código de cuatro letras.
- `modelos/MLP_12000.joblib`: modelo final sobre datos sintéticos.
- `datos/`: cuestionario, catálogo, etiquetas y resultados de 5 folds.
- `tests/`: pruebas de núcleo, base y flujo gráfico.

## Comprobación

```bash
python -m pytest -q tests/test_core.py tests/test_demografia.py
# Con escritorio Linux disponible o xvfb-run:
python tests/gui_smoke.py
```

PsicoLab es una actividad educativa exploratoria; no constituye diagnóstico ni prueba validada para selección laboral.
'@
}
@{ Ruta = 'RENDER.md'; Original = ''; Nuevo = '555EB9E0E6E702023ABD1D0A97DD251EC4AD15194156E330708757CEE7FA9243'; Contenido = @'
# PsicoLab en Render — 14 de noviembre de 2026

## Estado de entrega
Código preparado y comprobado localmente. No se ha creado un repositorio remoto ni un servicio de Render desde esta entrega. Es necesario conectar las cuentas para publicarlo. No hay URL pública todavía.

## 1. Subir a GitHub
Crea un repositorio PRIVADO nuevo para PsicoLab. No uses el repositorio de constancias.
Abre la carpeta que contiene `psicolab_core.py`, `web/` y `render.yaml` en VS Code.
En Control de código fuente, inicializa el repositorio y publica como privado.
No subas bases SQLite, CSV de participantes, exportaciones ni credenciales.
El CSV de datos sintéticos de entrenamiento sí forma parte del proyecto.

## 2. Publicar la prueba gratuita
En https://dashboard.render.com elige New → Blueprint, conecta GitHub y selecciona el repositorio.
Usa `render.yaml` de la raíz. Se crea UN Web Service Python en Free, sin disco y sin guardado.
Si prefieres New → Web Service, configura:

| Campo | Valor |
|---|---|
| Root Directory | Vacío si los archivos están en la raíz; si subiste la carpeta completa, su nombre |
| Build Command | `pip install -r requirements-web.txt` |
| Start Command | `uvicorn web.app:app --host 0.0.0.0 --port $PORT --workers 1 --no-access-log` |
| Health Check Path | `/api/salud` |
| Python | `.python-version` contiene `3.12` |
| PSICOLAB_GUARDAR_DESDE | `2026-11-19T00:00` |
| PSICOLAB_GUARDAR_HASTA | `2026-11-19T18:30` |
| OPENBLAS_NUM_THREADS | `1` |
| OMP_NUM_THREADS | `1` |

No definas PSICOLAB_DATA_DIR en Free. El servicio gratuito puede tardar en arrancar tras inactividad.
Prueba: inicio → consentimiento → datos → 20 respuestas → resultado con tres áreas.
Antes del 19 debe indicar modo de prueba. `/api/salud` indicará almacenamiento no configurado.

## 3. Recopilación con disco persistente
El calendario heredado propone el miércoles 18 a las 19:00, hora de Ciudad de México.
No hay tareas programadas: los cambios de plan, la exportación y el cierre son manuales.
Antes de recopilar, el responsable debe revisar el consentimiento (ver apartado final).
Para un servicio administrado por Blueprint, cambia `plan: free` por el plan de pago compatible seleccionado en Render; agrega bajo el servicio:

```yaml
disk:
  name: respuestas
  mountPath: /var/data
  sizeGB: 1
```

Agrega también al arreglo `envVars`:

```yaml
- key: PSICOLAB_DATA_DIR
  value: /var/data
```

Respeta la indentación del YAML: disk es hermano de envVars. Sincroniza el Blueprint y revisa el costo mostrado antes de contratar. Para un servicio creado manualmente, cambia el plan en Settings, agrega el disco en Disks y la variable en Environment.
No crees /var/data manualmente para simular el disco: no sería persistente.
Mantén una instancia y un worker para esta base SQLite.
`/api/salud` debe indicar `almacenamiento: listo`.
El guardado solo estará habilitado el 19 de noviembre de 2026 de 00:00 a antes de 18:30 (UTC−6).
Después del despliegue, comprueba que un registro de ensayo se conserva tras reiniciar, usando temporalmente una ventana de prueba y restaurando luego las fechas definitivas. Elimina ese registro de ensayo.
El acceso al sitio es público mediante su URL; el repositorio privado no restringe a los visitantes. No hay contraseña de clase.

## 4. Exportar y descargar las respuestas
El jueves 19 después de las 18:30, en Shell de Render:

```bash
python investigacion.py estado
python investigacion.py exportar --salida /var/data/respuestas_19nov.csv
```

Para descargar, configura una clave SSH en Render. Copia el destino SSH exacto de Connect → SSH de TU servicio. En PowerShell local, sustituye USUARIO y HOST por esos valores (no son tus credenciales de GitHub):

```powershell
cd "$env:USERPROFILE\Downloads"
scp USUARIO@HOST:/var/data/respuestas_19nov.csv .\respuestas_19nov.csv
Get-Item .\respuestas_19nov.csv
```

Usa OpenSSH moderno con SFTP (predeterminado en versiones recientes). La documentación de Render también muestra `scp -s` para clientes que soportan esa opción. No uses `-O` para forzar SCP antiguo.
Abre el CSV local y verifica columnas y número de registros contra `estado`. Conserva una copia protegida antes de retirar el servicio. No se agrega una ruta pública para descargar datos.
No borres el servicio/disco hasta verificar la copia. El cierre a las 19:00 que propone el PDF NO está automatizado.

## 5. Ejecutar localmente en Windows

```powershell
cd "C:\ruta\PsicoLab_2.0_Flujo_Simplificado"
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe -m pytest -q
.\.venv\Scripts\python.exe -m uvicorn web.app:app --reload
```

Abre http://127.0.0.1:8000. Sin PSICOLAB_DATA_DIR no se guardan respuestas.
Para entrenar/activar modelos localmente, instala `requirements-modelo.txt`, que ahora incluye pandas. No se reentrena en Render.

## 6. Consentimiento pendiente de aprobación del responsable
Se preservó el texto original de escritorio y web, como exigen las instrucciones existentes. NO debe asumirse que quedó listo para recopilar datos reales: todavía dice que son anónimos.
Propuesta de sustitución para revisar y aplicar EN AMBAS interfaces:

“Tu participación es voluntaria. Se recopilan edad, sexo, carrera, las 20 respuestas y el perfil estimado por la IA, asociados a un identificador aleatorio. No se solicitan nombres ni correos. Estos datos son seudonimizados, no irreversiblemente anónimos; la combinación de variables podría permitir identificación indirecta. En la versión web, los registros autorizados se almacenan en un servidor externo de Render, en la región seleccionada por el responsable. El resultado tiene fines educativos exploratorios y no constituye diagnóstico ni prueba validada de aptitud laboral. Puedes eliminar el registro de esta sesión desde la pantalla de resultados.”

Antes de aprobar el texto, el responsable debe completar su identidad y contacto, finalidad específica, plazo de conservación, región efectiva del servidor y canal de eliminación posterior a la sesión. La población configurada incluye 17 años; el responsable debe definir el procedimiento aplicable a menores. No se inventan estos datos en el código.
El borrador de respuestas se recupera en esta pestaña durante dos horas de inactividad; se elimina con Nuevo cuestionario o al rechazar y volver al inicio. No se usa localStorage. Al recargar un resultado, se vuelve al cuestionario y se recalcula conservando el mismo ID. Si el navegador bloquea sessionStorage, se continúa solo en memoria.

## Fuentes oficiales consultadas
- https://render.com/docs/deploy-fastapi
- https://render.com/docs/python-version
- https://render.com/docs/blueprint-spec
- https://render.com/docs/disks
- https://render.com/docs/free

El presupuesto aproximado del PDF no es una cotización actual: verifica en Render el plan y el disco elegidos.
'@
}
@{ Ruta = 'render.yaml'; Original = ''; Nuevo = '69AA6BD481A0EA0D92F968937EB0C1B4C84DBD4D3EC4413F4742943FAA78531F'; Contenido = @'
# Primera publicación: prueba gratuita, sin recopilación de respuestas.
services:
  - type: web
    name: psicolab-web
    runtime: python
    plan: free
    buildCommand: pip install -r requirements-web.txt
    startCommand: uvicorn web.app:app --host 0.0.0.0 --port $PORT --workers 1 --no-access-log
    healthCheckPath: /api/salud
    envVars:
      - key: PSICOLAB_GUARDAR_DESDE
        value: "2026-11-19T00:00"
      - key: PSICOLAB_GUARDAR_HASTA
        value: "2026-11-19T18:30"
      - key: OPENBLAS_NUM_THREADS
        value: "1"
      - key: OMP_NUM_THREADS
        value: "1"
'@
}
@{ Ruta = 'requirements-modelo.txt'; Original = 'C49CC692CBC78B904A853BD46F6EFF9A93CEA889CC9A7EBD1A512E36B1FF55CF'; Nuevo = 'BCD99DB9DF6A454841738A0F3F33DEB06DFAAC1C882B5EA7A46CF340B42FB9A4'; Contenido = @'
-r requirements.txt
pandas>=2.2,<3
numpy>=1.24,<3
scikit-learn==1.8.0
joblib>=1.3,<2
'@
}
@{ Ruta = 'tests/test_web_despliegue.py'; Original = ''; Nuevo = '082827467FDEBB64B93D77B1FD328FBE495C40F31FED0B9938239DCC45810C7D'; Contenido = @'
"""Regresiones para la publicación web y reintentos de red."""
from uuid import uuid4
from fastapi.testclient import TestClient
from web.app import app
import storage


def test_reintento_con_id_conserva_un_registro(monkeypatch, tmp_path):
    monkeypatch.setenv('PSICOLAB_DATA_DIR', str(tmp_path))
    monkeypatch.delenv('PSICOLAB_GUARDAR_DESDE', raising=False)
    monkeypatch.delenv('PSICOLAB_GUARDAR_HASTA', raising=False)
    datos = dict(consentimiento=True, edad=20, sexo='Femenino', carrera='Derecho',
                 respuestas=['A'] * 20, registro_id=str(uuid4()))
    with TestClient(app) as c:
        for _ in range(2):
            respuesta = c.post('/api/resultado', json=datos)
            assert respuesta.status_code == 200
            assert respuesta.json()['registro']['id'] == datos['registro_id']
            assert respuesta.headers['cache-control'] == 'no-store'
    assert len(storage.records()) == 1


def test_compresion_y_cache_de_estaticos():
    with TestClient(app) as c:
        pagina = c.get('/css/estilos.css', headers={'Accept-Encoding': 'gzip'})
        assert pagina.status_code == 200
        assert pagina.headers['content-encoding'] == 'gzip'
        assert pagina.headers['cache-control'] == 'no-cache'
        tarjeta = c.get('/tarjetas/INTJ.png')
        assert tarjeta.headers['cache-control'] == 'public, max-age=86400'
        assert tarjeta.headers['x-content-type-options'] == 'nosniff'
        assert tarjeta.headers['x-frame-options'] == 'DENY'


def test_base_y_codigo_no_son_publicos():
    with TestClient(app) as c:
        for ruta in ['/respuestas.sqlite3', '/storage.py', '/datos/entrenamiento_12000_sinteticos.csv', '/.env']:
            assert c.get(ruta).status_code == 404
'@
}
@{ Ruta = 'web/app.py'; Original = '5791900023FDF76352F54D226EE311A2D5A0469EF43264CEAF52140427F67B68'; Nuevo = '83974E0DA67F2264220B1E1AACCE82BC3A4FE91984487EA3A6E2EA8F5E4CE49E'; Contenido = @'
"""Punto de entrada del servidor: uvicorn web.app:app"""
from __future__ import annotations

import mimetypes
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from starlette.middleware.gzip import GZipMiddleware

from psicolab_core import ROOT
from version import VERSION

from . import servicio
from .config import leer_ventana
from .rutas import router

ESTATICO = Path(__file__).resolve().parent / 'estatico'

# Python toma los tipos de archivo del sistema; en Windows salen del registro y
# varían entre equipos (a veces .js llega como text/plain y el navegador no lo
# ejecuta). Se fijan para que el servidor responda igual en cualquier equipo.
mimetypes.add_type('text/javascript', '.js')
mimetypes.add_type('text/css', '.css')
mimetypes.add_type('font/woff2', '.woff2')


@asynccontextmanager
async def ciclo_de_vida(_app: FastAPI):
    leer_ventana()  # detiene el arranque si las fechas están mal escritas
    servicio.precargar_modelo()
    yield


def crear_app() -> FastAPI:
    app = FastAPI(title=f'PsicoLab {VERSION}', lifespan=ciclo_de_vida)
    app.add_middleware(GZipMiddleware, minimum_size=1000, compresslevel=5)

    @app.middleware('http')
    async def cabeceras(request, call_next):
        response = await call_next(request)
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['Referrer-Policy'] = 'no-referrer'
        response.headers['X-Frame-Options'] = 'DENY'
        if request.url.path.startswith('/api/'):
            response.headers['Cache-Control'] = 'no-store'
        elif request.url.path.startswith(('/tarjetas/', '/fuentes/')):
            response.headers['Cache-Control'] = 'public, max-age=86400'
        else:
            response.headers['Cache-Control'] = 'no-cache'
        return response

    app.include_router(router)
    app.mount('/tarjetas', StaticFiles(directory=ROOT / 'assets'), name='tarjetas')
    # Va al final: las pantallas web atienden todo lo que no sea /api, /docs o /tarjetas.
    app.mount('/', StaticFiles(directory=ESTATICO, html=True), name='pantallas')
    return app


app = crear_app()
'@
}
@{ Ruta = 'web/estatico/css/mejoras.css'; Original = ''; Nuevo = '67C1085DF0D485979229875F9AFA5FD72F493E1F93905B50B761890459DFA1AA'; Contenido = @'
/* Capa visual web: conserva la identidad y las tarjetas originales. */
body { background: radial-gradient(ellipse at top right, #fff5cf 0, transparent 45%), #f3f5fa; }
.cabecera { box-shadow: 0 3px 18px #1f25400c; }
.pantalla { animation: entrar .28s ease-out both; }
.panel { border-radius: 18px; box-shadow: 0 8px 32px #1f254008; overflow: hidden; }
.boton { border-radius: 12px; min-height: 46px; transition: transform .18s, box-shadow .18s, background-color .18s; }
.boton:disabled { opacity: .65; }
.boton:active:not(:disabled) { transform: translateY(1px) scale(.99); }
.boton:focus-visible, select:focus-visible { outline: 3px solid var(--azul); outline-offset: 3px; }
.boton-naranja { background: #bc3c10; }
.boton-verde { background: #067a36; }
.chip { border-radius: 999px; }
.chip-rosa { color: var(--marino); }
.bienvenida .descripcion { line-height: 1.65; }
.bienvenida .nota { line-height: 1.5; }
.campo select { border-radius: 10px; background-color: #f8f9fc; }
.pregunta { border-left: 3px solid transparent; padding-left: 8px; transition: border-color .2s; }
.pregunta.respondida { border-left-color: #16854d; }
.opcion { border-radius: 9px; min-height: 44px; margin-bottom: 6px; padding: 10px 12px; gap: 5px; transition: background-color .18s, border-color .18s; }
.opcion:has(input:checked) { background: #eaf2ff; border-color: var(--azul); }
.opcion:has(input:focus-visible) { outline: 2px solid var(--azul); outline-offset: 2px; }
.opcion input { width: 16px; height: 16px; }
.progreso { border: 0; border-radius: 20px; height: 9px; padding: 0; background: #e5eaf2; }
.progreso-barra { border: 0; border-radius: inherit; box-shadow: none; background: linear-gradient(90deg, #1e73e8, #7054cc); transition: width .25s ease; }
.pie-cuestionario { background: #ffffff; border-top: 1px solid #edf0f5; }
.trabajo { border-radius: 12px; animation: entrar .35s ease-out both; }
.trabajo-2 { animation-delay: .07s; }
.trabajo-3 { animation-delay: .14s; }
.panel-tarjeta img { border-radius: 10px; }
.codigo { overflow-wrap: anywhere; }
.desplazable { scrollbar-width: thin; scrollbar-color: #bdc6d6 transparent; }
@media (hover: hover) {
  .boton:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 6px 14px #1f25401c; }
  .opcion:hover { background-color: #f4f7fc; }
}
@media (max-width: 720px) {
  body { min-height: 100dvh; }
  .bienvenida h1 { font-size: 29px; }
  .panel { border-radius: 14px; }
  .acciones, .pie-panel { flex-wrap: wrap; gap: 10px; }
  .acciones .boton, .pie-panel .boton { flex: 1 1 140px; }
  .p-cuestionario .titulo-pantalla { font-size: 23px; }
  .texto-consentimiento .parrafos { line-height: 1.6; margin-left: 5px; margin-right: 5px; }
  .panel-tarjeta img { max-width: 372px; margin-left: auto; margin-right: auto; }
}
@keyframes entrar { from { opacity: 0; transform: translateY(9px); } to { opacity: 1; transform: none; } }
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation: none !important; transition: none !important; scroll-behavior: auto !important; }
}
'@
}
@{ Ruta = 'web/estatico/index.html'; Original = 'DA2FF4E61446DA55075A54B3307DC2B2279D4CAC842AF627B817F16504C57672'; Nuevo = '80C377AC3E4F62DB04DCE0804ED04799CBEC25BD9ECB4E84C08C1EBCD4F57ED1'; Contenido = @'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#F7D500">
  <meta name="description" content="Explora tus preferencias con PsicoLab: 20 preguntas y un perfil de inteligencia artificial con fines educativos.">
  <title>PsicoLab 2.0 | ¿Puede un algoritmo conocerte?</title>
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="/css/estilos.css">
  <link rel="stylesheet" href="/css/mejoras.css">
  <script type="module" src="/js/main.js"></script>
</head>
<body>
  <header class="cabecera">
    <div>
      <p class="marca">PsicoLab 2.0</p>
      <p class="lema">¿Puede un algoritmo conocerte? · Actividad exploratoria</p>
    </div>
    <div class="puntos" aria-hidden="true"><span></span><span></span><span></span><span></span></div>
  </header>
  <main id="app" class="contenido"></main>
  <noscript><p class="contenido">Activa JavaScript en tu navegador para usar PsicoLab.</p></noscript>
</body>
</html>
'@
}
@{ Ruta = 'web/estatico/js/main.js'; Original = '48C100A0F656C1B1107C0DC4A72B4D5D982E8A64C241E563E65AC706E7D42B61'; Nuevo = 'D176C7F25601EAC94CC5F820BF5749259D572AA10AB0501D7B019C033DDFE855'; Contenido = @'
import { obtenerCatalogo } from './api.js';
import { datosCompletos, estado } from './estado.js';
import { boton, el, panel, pantalla, vigilarDesborde } from './ui.js';
import { mostrarInicio } from './pantallas/inicio.js';
import { mostrarConsentimiento, mostrarRechazo } from './pantallas/consentimiento.js';
import { mostrarDatos } from './pantallas/datos.js';
import { mostrarCuestionario } from './pantallas/cuestionario.js';
import { mostrarResultado } from './pantallas/resultado.js';

import { guardarSesion, recuperarSesion } from './sesion.js';

const PANTALLAS = {
  inicio: mostrarInicio,
  consentimiento: mostrarConsentimiento,
  rechazo: mostrarRechazo,
  datos: mostrarDatos,
  cuestionario: mostrarCuestionario,
  resultado: mostrarResultado,
};

const contenedor = document.getElementById('app');
const app = { catalogo: null, ir };
let limpiezas = [];
document.addEventListener('change', () => guardarSesion());
window.addEventListener('pagehide', () => guardarSesion());

// Mismas reglas que la app de escritorio: sin consentimiento no hay datos ni
// cuestionario, y sin datos generales no hay cuestionario ni resultado.
function pantallaPermitida(nombre) {
  if (['datos', 'cuestionario', 'resultado'].includes(nombre) && !estado.consentimiento) return 'consentimiento';
  if (['cuestionario', 'resultado'].includes(nombre) && !datosCompletos(app.catalogo.carreras)) return 'datos';
  if (nombre === 'resultado' && !estado.resultado) return 'cuestionario';
  return nombre in PANTALLAS ? nombre : 'inicio';
}

function ir(nombre, { historial = true } = {}) {
  const destino = pantallaPermitida(nombre);
  limpiezas.forEach((limpiar) => limpiar());
  limpiezas = [];
  contenedor.replaceChildren();
  PANTALLAS[destino](contenedor, app);
  contenedor.querySelectorAll('.desplazable').forEach((nodo) => limpiezas.push(vigilarDesborde(nodo)));
  const titulo = contenedor.querySelector('h1');
  if (titulo) { titulo.tabIndex = -1; titulo.focus({ preventScroll: true }); }
  document.title = `${titulo?.textContent || 'Inicio'} | PsicoLab 2.0`;
  guardarSesion(destino);
  window.scrollTo(0, 0);
  // Guardar cada pantalla en el historial hace que el botón "Atrás" del
  // navegador o del celular regrese a la pantalla anterior sin salir del sitio.
  if (historial) history.pushState({ pantalla: destino }, '');
  else history.replaceState({ pantalla: destino }, '');
}

window.addEventListener('popstate', (evento) => {
  if (app.catalogo) ir(evento.state?.pantalla ?? 'inicio', { historial: false });
});

async function arrancar() {
  contenedor.replaceChildren(el('p', { class: 'cargando' }, 'Cargando PsicoLab…'));
  try {
    app.catalogo = await obtenerCatalogo();
  } catch (error) {
    contenedor.replaceChildren(pantalla('rechazo', panel({},
      el('h1', { class: 'titulo-pantalla' }, 'No se pudo cargar el cuestionario'),
      el('p', { class: 'explicacion' }, error.message),
      el('div', { class: 'acciones' }, boton('Reintentar', arrancar, 'primario')))));
    return;
  }
  ir(recuperarSesion(app.catalogo.carreras) || 'inicio', { historial: false });
}

arrancar();
'@
}
@{ Ruta = 'web/estatico/js/pantallas/cuestionario.js'; Original = '08A168A7A69EFB727B956968F436BECC4E832721D2D975707B2A506CA2F4161E'; Nuevo = 'BE7DEE22E270533DEAE49513C293EDB21D2ABB3CF0556E50ACB66AAFB0782B54'; Contenido = @'
import { guardarSesion } from '../sesion.js';
import { calcularResultado } from '../api.js';
import { estado, preguntasFaltantes } from '../estado.js';
import { DIMENSIONES, PREGUNTAS_POR_DIMENSION } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';

function encabezadoDimension(numero) {
  const { titulo, color } = DIMENSIONES[numero];
  return el('p', { class: 'dimension', style: `color: ${color}` }, `DIMENSIÓN ${numero + 1} · ${titulo}`);
}

function bloquePregunta(pregunta, indice, alResponder) {
  const numero = String(indice + 1).padStart(2, '0');
  const idTexto = `pregunta-${indice}`;
  return el('div', { class: 'pregunta', role: 'radiogroup', 'aria-labelledby': idTexto },
    el('p', { class: 'pregunta-texto', id: idTexto }, `${numero}. ${pregunta.pregunta} *`),
    ['A', 'B'].map((letra) => el('label', { class: 'opcion' },
      el('input', {
        type: 'radio',
        name: idTexto,
        value: letra,
        checked: estado.respuestas[indice] === letra,
        onchange: () => alResponder(letra),
      }),
      el('span', {}, `${letra}) ${pregunta[letra]}`))));
}

export function mostrarCuestionario(contenedor, app) {
  const { preguntas } = app.catalogo;
  const total = preguntas.length;
  const barra = el('div', { class: 'progreso-barra' });
  const contador = el('p', { class: 'progreso-texto', role: 'status', 'aria-live': 'polite' });
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const verResultado = boton('Ver mi resultado', () => enviar(), 'pendiente');
  const bloques = preguntas.map((pregunta, i) => bloquePregunta(pregunta, i, (letra) => responder(i, letra)));

  function actualizar() {
    const respondidas = total - preguntasFaltantes(total).length;
    barra.style.width = `${(100 * respondidas) / total}%`;
    barra.parentElement?.setAttribute('aria-valuenow', String(respondidas));
    bloques.forEach((bloque, i) => bloque.classList.toggle('respondida', Boolean(estado.respuestas[i])));
    contador.textContent = `${respondidas} de ${total} preguntas respondidas`;
    verResultado.className = `boton boton-${respondidas === total ? 'primario' : 'pendiente'}`;
  }

  function responder(indice, letra) {
    estado.respuestas[indice] = letra;
    estado.resultado = null;
    aviso.textContent = '';
    actualizar();
  }

  async function enviar() {
    const faltantes = preguntasFaltantes(total);
    if (faltantes.length) {
      // Igual que en escritorio: no se calcula una predicción parcial y se
      // lleva al participante al primer reactivo sin responder.
      aviso.textContent = `Faltan las preguntas: ${faltantes.map((i) => i + 1).join(', ')}`;
      bloques[faltantes[0]].scrollIntoView({ block: 'start' });
      bloques[faltantes[0]].querySelector('input').focus({ preventScroll: true });
      return;
    }
    if (verResultado.disabled) return;
    verResultado.disabled = true;
    verResultado.textContent = 'Calculando tu perfil…';
    verResultado.setAttribute('aria-busy', 'true');
    bloques.forEach((b) => b.querySelectorAll('input').forEach((n) => n.disabled = true));
    // Mantener el mismo ID si se reintenta tras una interrupción de red.
    estado.registroId ||= crypto.randomUUID();
    guardarSesion('cuestionario');
    try {
      const resultado = await calcularResultado({
        consentimiento: true,
        edad: Number(estado.edad),
        sexo: estado.sexo,
        carrera: estado.carrera,
        respuestas: preguntas.map((_, i) => estado.respuestas[i]),
        registro_id: estado.registroId,
      });
      if (!verResultado.isConnected) return;
      estado.resultado = resultado;
      if (estado.resultado.registro.guardado) estado.registroId = estado.resultado.registro.id;
      app.ir('resultado');
    } catch (error) {
      aviso.textContent = error.message;
      verResultado.disabled = false;
      verResultado.textContent = 'Ver mi resultado';
      verResultado.removeAttribute('aria-busy');
      bloques.forEach((b) => b.querySelectorAll('input').forEach((n) => n.disabled = false));
    }
  }

  contenedor.append(pantalla('cuestionario',
    el('h1', { class: 'titulo-pantalla' }, 'Cuestionario de preferencias'),
    el('p', { class: 'subtitulo' },
      `${estado.edad} años · ${estado.sexo} · ${estado.carrera}  |  Todas las preguntas son obligatorias.`),
    panel({},
      el('div', { class: 'desplazable lista-preguntas' }, bloques.map((bloque, i) => [
        i % PREGUNTAS_POR_DIMENSION === 0 && encabezadoDimension(i / PREGUNTAS_POR_DIMENSION),
        bloque,
        el('div', { class: 'separador' }),
      ])),
      el('div', { class: 'pie-cuestionario' },
        el('div', { class: 'progreso', role: 'progressbar', 'aria-label': 'Preguntas respondidas', 'aria-valuemin': '0', 'aria-valuemax': String(total), 'aria-valuenow': '0' }, barra),
        contador,
        aviso,
        el('div', { class: 'acciones' },
          boton('← Datos generales', () => app.ir('datos')),
          verResultado)))));
  actualizar();
}
'@
}
@{ Ruta = 'web/estatico/js/pantallas/resultado.js'; Original = '848A8AEE793223A7A115F15BD9F706E521DC7791F767F2C32B7641BDA1EDFDF3'; Nuevo = '65BA684EBFD9F117EC4B9DBA4001C8D366E0A785BF4522B1E9547EC36AB21575'; Contenido = @'
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
'@
}
@{ Ruta = 'web/estatico/js/sesion.js'; Original = ''; Nuevo = 'C529036BDE22FD6DF9B22B2B21CEC143AD99C2DEFAFB2F1DEF8D58B8F21BB763'; Contenido = @'
// Solo esta pestaña. Nunca usamos localStorage ni enviamos borradores al servidor.
import { estado } from './estado.js';
const CLAVE = 'psicolab.sesion.v1';
const DURACION = 2 * 60 * 60 * 1000;
export function guardarSesion(pantalla = null) {
  try {
    if (!estado.consentimiento) { sessionStorage.removeItem(CLAVE); return; }
    const anterior = JSON.parse(sessionStorage.getItem(CLAVE) || 'null');
    sessionStorage.setItem(CLAVE, JSON.stringify({
      version: 1, vence: Date.now() + DURACION,
      pantalla: pantalla || anterior?.pantalla || 'datos', datos: estado,
    }));
  } catch { /* La actividad funciona aunque el navegador bloquee el almacenamiento. */ }
}
export function recuperarSesion(carreras) {
  try {
    const guardado = JSON.parse(sessionStorage.getItem(CLAVE) || 'null');
    if (!guardado || guardado.version !== 1 || guardado.vence <= Date.now()) throw new Error();
    const d = guardado.datos;
    if (d?.consentimiento !== true || !d.respuestas || typeof d.respuestas !== 'object') throw new Error();
    const respuestas = {};
    for (const [k, v] of Object.entries(d.respuestas)) {
      if (!/^(?:[0-9]|1[0-9])$/.test(k) || !['A', 'B'].includes(v)) throw new Error();
      respuestas[k] = v;
    }
    const id = typeof d.registroId === 'string' && /^[0-9a-f-]{36}$/i.test(d.registroId) ? d.registroId : null;
    Object.assign(estado, { consentimiento: true,
      edad: Number.isInteger(Number(d.edad)) && Number(d.edad) >= 17 && Number(d.edad) <= 65 ? String(d.edad) : '',
      sexo: ['Masculino', 'Femenino'].includes(d.sexo) ? d.sexo : '',
      carrera: carreras.includes(d.carrera) ? d.carrera : '', respuestas, registroId: id,
      resultado: null });
    // Los resultados se vuelven a calcular; el identificador evita duplicar el registro.
    return guardado.pantalla === 'resultado' ? 'cuestionario' : guardado.pantalla;
  } catch { try { sessionStorage.removeItem(CLAVE); } catch {} return 'inicio'; }
}
'@
}
@{ Ruta = 'web/estatico/js/ui.js'; Original = '5D259664601D3C6ED670F5A314BBBCA2F78331461827C205115DE2EF6F8680C1'; Nuevo = '775966C1655C0CDBC873416A8FBE4745421AF44BAB7666BB5EDE5130FEBB7496'; Contenido = @'
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
'@
}
 )
# Validar TODOS antes de modificar UNO.
foreach ($Archivo in $Archivos) {
    $Ruta = Join-Path $Raiz $Archivo.Ruta
    if (Test-Path -LiteralPath $Ruta) {
        if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) { throw "No es un archivo: $Ruta" }
        $Hash = (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash
        if ($Hash -ne $Archivo.Original -and $Hash -ne $Archivo.Nuevo) { throw "Archivo con cambios desconocidos: $Ruta. No se modificó nada." }
    } elseif ($Archivo.Original) { throw "Falta el archivo original: $Ruta. No se modificó nada." }
}
foreach ($Archivo in $Archivos) {
    $Ruta = Join-Path $Raiz $Archivo.Ruta
    if ((Test-Path -LiteralPath $Ruta) -and (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash -eq $Archivo.Nuevo) { continue }
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($Ruta)) | Out-Null
    $Texto = ($Archivo.Contenido -replace "`r`n", "`n") + "`n"
    [System.IO.File]::WriteAllText($Ruta, $Texto, $Utf8)
    if ((Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash -ne $Archivo.Nuevo) { throw "Error al verificar: $Ruta" }
    Write-Host "Actualizado: $($Archivo.Ruta)"
}
Write-Host 'Listo. Consulta RENDER.md; ejecuta las pruebas antes de publicar.'
