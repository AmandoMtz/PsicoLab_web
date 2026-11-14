# Ajustes del 14/11/2026: tarjeta grande, carreras FADYCS y cuestionario de una pregunta por pantalla. UTF-8 con BOM para PowerShell 5.1.
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath '.\psicolab_core.py')) { throw 'Abre PowerShell en la carpeta que contiene psicolab_core.py.' }
$Raiz = (Get-Location).Path
$Utf8 = New-Object System.Text.UTF8Encoding($false)
function Hash-Texto([string]$Texto) {
    $Sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($Sha.ComputeHash($Utf8.GetBytes($Texto)))).Replace('-', '') }
    finally { $Sha.Dispose() }
}
$Archivos = @(
@{ Ruta = 'AGENTS.md'; Original = '4BE136350163DC5CDB85479C7278077B665318EE777E49EF160F9F55F5063C5A'; Nuevo = '5B03D684C1E6D10F7EE06F70A29EF4CB0038034B8CFE078B54B01E452E6EEDA4'; Contenido = @'
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


## 14. Ajustes del 14/11/2026 (tras ver el sitio publicado)
El usuario pidió tres cambios, solo en la web (API y núcleo intactos):
1. La tarjeta del resultado es más grande (columna de 480 px en escritorio) y se abre completa al tocarla.
2. La carrera se muestra con los nombres oficiales de la FADYCS (`js/carreras.js`): Licenciatura en Ciencias de la Comunicación, Derecho, Economía y Finanzas, Gestión y Desarrollo Turístico, Idioma Inglés y Psicología. Es solo la etiqueta: el valor enviado a la API sigue siendo el del catálogo, porque `career_areas` del núcleo busca por ese nombre. Si el catálogo cambia, se ajustan las claves de `carreras.js`.
3. El cuestionario pasó de bloques de cinco preguntas a **una pregunta por pantalla**: opciones grandes, la elegida se rellena de azul marino con la letra en amarillo y la marca "Elegida", avance automático a los 450 ms (solo con toque o clic; con teclado no avanza solo), barra de 20 segmentos clicable y botón "Descubrir mi perfil" al final. Misma API y mismo envío de las 20 respuestas en orden.
Pendiente: revisión visual en Chrome/Edge y en celular real, y volver a ejecutar `pytest`.

'@
}
@{ Ruta = 'web/estatico/css/estilos.css'; Original = '36B45AC7D5523BF6D77017A8C7503B0CCF22EABBDE7B48ACEBB306C0B8DDBB80'; Nuevo = 'F0EF1DCA824C5D77B0F9DD3980676EEEAFE7575F84C7F379CEE2B67A5E873BD0'; Contenido = @'
/* PsicoLab: interfaz web independiente del diseño de escritorio. */
:root {
  --fondo:#f8f7f4; --blanco:#fff; --marino:#292441; --gris:#6b687b;
  --amarillo:#f4d750; --rosa:#efadd0; --azul:#6452ca; --azul-claro:#eeeafa;
  --naranja:#b7442d; --verde:#25765c; --linea:#e5e2eb; --aviso:#a5372b;
  --exito:#226c50; --lila:#eee9fc; --menta:#e6f2eb;
  font-family:Inter, 'Segoe UI', Arial, sans-serif; color:var(--marino); font-size:16px;
  font-synthesis:none; -webkit-font-smoothing:antialiased;
}
* { box-sizing:border-box; }
[hidden] { display:none !important; }
body { margin:0; background:var(--fondo); min-height:100vh; }
h1,h2,h3,p { margin:0; }
button,input,select { font:inherit; }
button,a,input,select,summary { -webkit-tap-highlight-color:transparent; }
button,a,summary { touch-action:manipulation; }
button { cursor:pointer; }
a { color:inherit; }
button:focus-visible,a:focus-visible,input:focus-visible,select:focus-visible,summary:focus-visible { outline:3px solid #8066de; outline-offset:4px; }
h1:focus,h2[tabindex]:focus { outline:none; }
.saltar { position:fixed; left:16px; top:-100px; z-index:20; background:white; padding:12px; }
.saltar:focus { top:10px; }
.cabecera { background:#fffdf9; border-bottom:1px solid var(--linea); }
.cabecera-interior { max-width:1240px; margin:auto; padding:20px 32px; display:flex; align-items:center; justify-content:space-between; gap:20px; }
.identidad { display:flex; gap:12px; align-items:center; }
.simbolo { display:grid; place-items:center; background:var(--amarillo); width:46px; height:46px; border-radius:15px 15px 15px 4px; font-weight:850; font-size:32px; line-height:1; }
.marca { font-size:24px; font-weight:800; letter-spacing:-1px; }
.marca span { font-size:11px; padding:4px 6px; margin-left:7px; background:#f0eef5; border-radius:5px; vertical-align:middle; letter-spacing:.3px; }
.lema { margin-top:4px; font-size:11px; color:var(--gris); }
.sello { display:flex; align-items:center; gap:8px; font-size:12px; color:var(--gris); }
.sello i,.punto { display:inline-block; width:7px; height:7px; border-radius:50%; background:#8a73cb; }
.contenido { width:min(1240px,100%); margin:auto; padding:0 32px; }
.pantalla { padding:36px 0 48px; }
.pie-sitio { max-width:1176px; margin:0 auto; border-top:1px solid var(--linea); padding:24px 0; display:flex; gap:18px; justify-content:space-between; align-items:center; color:var(--gris); font-size:11px; }
.pie-sitio strong { font-size:17px; color:var(--marino); }
.sobrelinea { display:flex; align-items:center; gap:9px; font-size:10px; line-height:1.6; font-weight:750; letter-spacing:1.6px; color:#73608b; }
.hero { display:grid; grid-template-columns:1.1fr 1fr; gap:42px; align-items:center; min-height:490px; padding:24px 0 36px; }
.hero h1 { font-size:clamp(36px,4.4vw,58px); font-weight:800; line-height:1.08; letter-spacing:-2.8px; max-width:610px; margin:22px 0; }
.hero h1 span { display:block; }
.acento { color:#7360b8; }
.descripcion { color:var(--gris); line-height:1.75; font-size:15px; max-width:480px; }
.hero-acciones { display:flex; flex-wrap:wrap; gap:16px; align-items:center; margin:28px 0 34px; }
.boton { display:inline-flex; justify-content:center; align-items:center; text-align:center; gap:9px; min-height:46px; border:1px solid transparent; padding:13px 20px; border-radius:12px; font-size:13px; font-weight:650; text-decoration:none; line-height:1.3; }
.boton-primario { color:white; background:var(--marino); box-shadow:0 6px 12px #29244112; }
.boton-secundario { color:var(--marino); background:#fff; border-color:var(--linea); }
.boton-marino { color:var(--marino); background:var(--amarillo); }
.boton-naranja { color:var(--gris); background:white; border-color:var(--linea); }
.boton-verde { color:#8a312c; background:white; border-color:#e5cfcd; }
.boton:disabled { cursor:wait; opacity:.6; }
.microtexto { color:var(--gris); font-size:11px; line-height:1.6; }
.hero-datos { display:flex; gap:30px; }
.hero-datos>div { display:flex; flex-direction:column; gap:4px; }
.hero-datos>div+div { border-left:1px solid #ded9e7; padding-left:28px; }
.hero-datos strong { font-size:25px; font-weight:750; letter-spacing:-.8px; }
.hero-datos span { font-size:10px; color:var(--gris); }
.hero-visual { position:relative; min-height:440px; border-radius:38% 42% 30% 45%; background:#eae3f4; isolation:isolate; }
.tarjeta-demo { position:absolute; width:228px; height:auto; border:8px solid white; border-radius:18px; box-shadow:0 20px 35px #30244522; }
.tarjeta-atras { top:68px; left:17px; transform:rotate(-12deg); }
.tarjeta-frente { right:12px; top:48px; transform:rotate(9deg); }
.etiqueta-flotante { position:absolute; z-index:3; background:var(--amarillo); top:9px; left:22px; border-radius:9px; padding:12px 14px; font-size:12px; font-weight:700; transform:rotate(-4deg); box-shadow:0 7px 16px #2924410b; }
.etiqueta-ejemplo { position:absolute; bottom:16px; left:15px; right:15px; text-align:center; font-size:9px; color:#6a5b7d; }
.orbita { position:absolute; border-radius:50%; z-index:-1; }
.orbita-uno { width:90px; height:90px; background:#f1c1d9; left:-12px; bottom:25px; }
.orbita-dos { width:65px; height:65px; background:#c6ddd3; right:-8px; top:0; }
.como-funciona { padding:22px 0 28px; }
.seccion-intro { display:flex; align-items:center; justify-content:space-between; margin-bottom:18px; gap:16px; }
.seccion-intro h2 { font-size:21px; letter-spacing:-.5px; }
.pasos-inicio { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.paso-inicio { display:flex; align-items:flex-start; gap:16px; padding:24px 22px; border-radius:17px; }
.rosa { background:#f6e8ef; }.lila { background:#ece8f5; }.menta { background:#e7f0e9; }
.numero-paso { font-size:13px; font-weight:750; border:1px solid #29244123; border-radius:50%; min-width:30px; height:30px; display:grid; place-items:center; }
.paso-inicio h3 { font-size:14px; margin:4px 0 9px; }
.paso-inicio p { font-size:12px; line-height:1.7; color:var(--gris); }
.aviso-suave { display:flex; gap:12px; align-items:center; color:var(--gris); font-size:11px; line-height:1.7; padding:16px 0 0; }
.icono-nota { border:1px solid #aaa4b7; width:20px; height:20px; border-radius:50%; display:grid; place-items:center; flex-shrink:0; }
.recorrido { max-width:1176px; margin:24px auto 0; }
.recorrido ol { list-style:none; display:flex; margin:0; padding:16px 24px; border:1px solid var(--linea); border-radius:14px; background:#ffffff90; }
.recorrido li { flex:1; display:flex; align-items:center; gap:9px; color:#9993a2; font-size:12px; }
.recorrido li:last-child { flex:0 0 auto; }
.recorrido li:not(:last-child)::after { content:''; height:1px; flex:1; margin:0 20px 0 10px; background:var(--linea); }
.paso-indice { display:grid; place-items:center; width:25px; height:25px; border-radius:50%; background:#eeecf0; flex-shrink:0; font-size:11px; }
.recorrido .actual { color:var(--marino); font-weight:650; }.actual .paso-indice { background:var(--amarillo); }
.recorrido .completo { color:#5d7769; }.completo .paso-indice { background:#e1eee6; }
.encabezado-pagina { margin-bottom:28px; }
.titulo-pantalla { font-size:clamp(28px,3vw,38px); line-height:1.18; letter-spacing:-1.25px; margin:10px 0 12px; }
.subtitulo { font-size:14px; line-height:1.7; color:var(--gris); max-width:760px; }
.panel { background:var(--blanco); border:1px solid var(--linea); border-radius:20px; }
.franja { display:none; }
.p-consentimiento,.p-rechazo { max-width:880px; margin:auto; }
.texto-consentimiento { padding:32px 36px; }
.texto-consentimiento h2 { font-size:17px; margin-bottom:24px; }
.parrafos { color:#5f5a6d; font-size:14px; line-height:1.85; }
.parrafos p+p { margin-top:18px; }
.pie-panel { display:flex; justify-content:space-between; gap:12px; padding:20px 36px; border-top:1px solid var(--linea); background:#fcfbfd; border-radius:0 0 20px 20px; }
.p-rechazo .panel { padding:36px; }
.explicacion { color:var(--gris); line-height:1.7; margin:15px 0 25px; }
.acciones { display:flex; justify-content:space-between; align-items:center; gap:12px; }
.datos-layout { display:grid; grid-template-columns:minmax(0,1.65fr) minmax(250px,1fr); gap:24px; align-items:start; }
.formulario-datos { padding:30px; }
.campos { display:grid; grid-template-columns:1fr 1fr; gap:20px; margin-bottom:28px; }
.campo label, .carreras legend { display:block; font-size:13px; font-weight:650; margin-bottom:11px; }
.campo select { width:100%; min-height:48px; border:1px solid #dcd7e5; border-radius:10px; background:#fcfbfd; color:var(--marino); padding:10px 12px; font-size:14px; }
.carreras { margin:0; padding:0; border:0; }
.carreras-grid { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
.carrera-opcion { position:relative; display:flex; align-items:center; gap:10px; border:2px solid var(--linea); border-radius:12px; padding:14px; cursor:pointer; min-height:70px; font-size:13px; }
.carrera-opcion input { position:absolute; width:16px; height:16px; right:8px; top:8px; opacity:0; }
.carrera-opcion:has(input:checked) { border-color:var(--marino); background:var(--marino); color:#fff; box-shadow:0 8px 18px #29244126; }
.carrera-opcion:has(input:checked) .carrera-icono { background:var(--amarillo); color:var(--marino); }
.carrera-opcion:has(input:focus-visible) { outline:3px solid #8066de; outline-offset:3px; }
.carrera-opcion:has(input:checked)::after { content:'✓'; color:var(--amarillo); position:absolute; right:10px; top:6px; font-size:13px; font-weight:800; }
.facultad { font-size:12px; line-height:1.5; color:var(--gris); margin:-4px 0 12px; }
.carrera-nombre { line-height:1.35; padding-right:10px; }
.carrera-icono { background:#f0edf5; border-radius:8px; min-width:31px; height:31px; display:grid; place-items:center; font-size:17px; color:#79678f; }
.datos-nota { background:#ece7f3; padding:30px; border-radius:20px; }
.icono-grande { display:grid; place-items:center; background:var(--amarillo); border-radius:14px; height:50px; width:50px; font-size:24px; margin-bottom:24px; }
.datos-nota h2 { font-size:24px; line-height:1.3; letter-spacing:-.5px; }
.datos-nota p { font-size:13px; color:#71657e; line-height:1.8; margin-top:18px; }
.mini-pill { display:inline-block; border:1px solid #c9bfd8; border-radius:20px; font-size:11px; padding:8px 12px; margin-top:24px; }
.aviso { font-size:12px; line-height:1.6; color:var(--aviso); }
.formulario-datos .aviso { margin-top:18px; }.formulario-datos .acciones { margin-top:20px; }
/* Cuestionario: una pregunta por pantalla, opciones grandes y selección muy marcada. */
.panel-pregunta { max-width:860px; margin:0 auto; padding:28px 32px 0; }
.cabecera-pregunta { display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:10px 16px; margin-bottom:16px; }
.tema-chip { display:inline-block; padding:7px 14px; border-radius:999px; font-size:12px; font-weight:750; background:var(--lila); color:#4b3a8c; }
.tema-chip[data-bloque="1"] { background:#fbe6f0; color:#8b2f5f; }
.tema-chip[data-bloque="2"] { background:var(--menta); color:#1f6249; }
.tema-chip[data-bloque="3"] { background:#fbf0b8; color:#6a5710; }
.pregunta-numero { font-size:13px; font-weight:700; color:var(--gris); }
.segmentos { display:flex; gap:4px; margin-bottom:14px; }
.segmento { position:relative; flex:1; min-width:0; height:10px; padding:0; border:0; border-radius:6px; background:#e3dfe9; }
.segmento::before { content:''; position:absolute; inset:-9px -1px; }
.segmento.hecha { background:#8870bd; }
.segmento.actual { background:var(--marino); box-shadow:0 0 0 3px #29244126; }
.segmento:disabled { cursor:wait; }
.pista-grupo { font-size:13px; line-height:1.6; color:var(--gris); margin-bottom:4px; }
.pregunta { border:0; padding:14px 0 8px; margin:0; min-width:0; }
.pregunta legend { padding:0; margin-bottom:18px; }
.pregunta-titulo { font-size:clamp(21px,2.8vw,29px); font-weight:800; line-height:1.3; letter-spacing:-.6px; }
.opciones { display:grid; grid-template-columns:1fr; gap:14px; }
.opcion { position:relative; display:flex; gap:16px; align-items:center; min-height:88px; cursor:pointer; background:#fff; border:2px solid #d9d3e4; border-radius:16px; padding:16px 20px; font-size:17px; line-height:1.5; color:var(--marino); }
.opcion input { position:absolute; width:16px; height:16px; opacity:0; }
.letra-opcion { flex-shrink:0; display:grid; place-items:center; width:42px; height:42px; border:2px solid #cfc7dc; border-radius:12px; color:#7a6e8d; font-size:17px; font-weight:800; }
.texto-opcion { flex:1; }
.marca-elegida { display:none; flex-shrink:0; font-size:12px; font-weight:800; color:var(--amarillo); white-space:nowrap; }
.opcion:has(input:checked) { background:var(--marino); border-color:var(--marino); color:#fff; box-shadow:0 10px 24px #29244133; }
.opcion:has(input:checked) .letra-opcion { background:var(--amarillo); border-color:var(--amarillo); color:var(--marino); }
.opcion:has(input:checked) .marca-elegida { display:inline; }
.opcion:has(input:focus-visible) { outline:3px solid #8066de; outline-offset:3px; }
.opcion:has(input:disabled) { cursor:wait; opacity:.6; }
.panel-pregunta>.aviso:not(:empty) { margin:16px 0 0; }
.pie-cuestionario { padding:24px 0; }
.resultado-encabezado { display:flex; gap:32px; align-items:center; justify-content:space-between; margin-bottom:28px; }
.resultado-encabezado>div:first-child { max-width:740px; }
.perfil-insignia { background:var(--amarillo); border-radius:20px; padding:20px 28px; min-width:185px; text-align:center; transform:rotate(2deg); flex-shrink:0; }
.perfil-insignia small { font-size:8px; letter-spacing:1.5px; font-weight:700; }.perfil-insignia strong { display:block; font-size:36px; letter-spacing:2px; margin:7px 0; }.perfil-insignia>span { font-size:11px; display:block; max-width:210px; }
.paneles { display:grid; grid-template-columns:480px minmax(0,1fr); gap:24px; align-items:start; }
.panel-tarjeta { padding:16px; background:#eeeaf5; border-color:#e3dced; }
.tarjeta-marco { border-radius:14px; background:white; padding:6px; box-shadow:0 6px 22px #35244510; }
.tarjeta-enlace { display:block; cursor:zoom-in; }
.panel-tarjeta img { display:block; width:100%; height:auto; border-radius:10px; }
.descargar { width:100%; margin:16px 0 10px; }.panel-tarjeta .microtexto { text-align:center; }
.panel-trabajos { padding:28px; }
.panel-trabajos h2 { margin:10px 0 12px; font-size:27px; letter-spacing:-.7px; }
.intro-trabajos { font-size:13px; line-height:1.7; color:var(--gris); margin-bottom:22px; }
.trabajo { display:flex; align-items:flex-start; gap:15px; padding:20px; border-radius:13px; margin:10px 0; }
.trabajo-1 { background:#f8eaf1; }.trabajo-2 { background:#eeeafa; }.trabajo-3 { background:#e7f2ec; }
.trabajo-numero { font-size:12px; opacity:.55; margin-top:3px; font-weight:650; }
.trabajo h3 { font-size:15px; line-height:1.4; margin-bottom:7px; }.trabajo p { font-size:12px; line-height:1.65; color:#756b7e; }
.reflexion { display:flex; gap:13px; padding:18px 0; margin-top:12px; border-top:1px dashed #ded6e7; }.reflexion>span { font-size:24px; color:#9674b9; }.reflexion h3 { font-size:12px; margin:5px 0 8px; }.reflexion p { font-size:12px; line-height:1.7; color:var(--gris); }
.panel-trabajos .nota { font-size:10px; color:var(--gris); line-height:1.6; }
.resultado-cierre { display:flex; justify-content:space-between; align-items:center; gap:24px; padding:28px 0; }.resultado-cierre h2 { font-size:16px; margin-bottom:7px; }.resultado-cierre p { font-size:12px; color:var(--gris); line-height:1.6; }
.registro { background:#eeedf4; border-radius:12px; padding:15px 18px; font-size:12px; line-height:1.6; }.registro .aviso { color:#70637c; }.registro .exito { color:var(--exito); }.registro .codigo { color:var(--gris); overflow-wrap:anywhere; margin:5px 0 12px; }
.acerca-resultado { margin:20px 0 0; font-size:12px; color:var(--gris); }.acerca-resultado summary { cursor:pointer; padding:10px 0; }.aviso-ia { line-height:1.7; max-width:850px; }
.cargando { text-align:center; padding:100px 20px; color:var(--gris); }
@media (min-width:1440px) { .hero { padding-top:44px; padding-bottom:50px; } }
@media (max-width:1050px) {
  .hero { gap:20px; }.hero h1 { font-size:44px; }.tarjeta-demo { width:190px; }.hero-visual { min-height:380px; }.tarjeta-atras { left:5px; }.tarjeta-frente { right:0; }
  .recorrido,.pie-sitio { margin-left:32px; margin-right:32px; }
  .paneles { grid-template-columns:400px minmax(0,1fr); }.resultado-cierre { align-items:flex-start; flex-direction:column; }
  .paso-inicio { padding:20px 16px; gap:10px; }.datos-layout { grid-template-columns:minmax(0,1.5fr) minmax(240px,1fr); }
}
@media (max-width:760px) {
  .cabecera-interior { padding:16px 20px; }.sello { display:none; }.contenido { padding:0 20px; }.pantalla { padding-top:25px; }.pie-sitio { margin:0 20px; flex-wrap:wrap; gap:12px; }.pie-sitio>span:last-child { width:100%; }
  .hero { grid-template-columns:1fr; gap:30px; padding:10px 0 24px; }.hero h1 { font-size:46px; letter-spacing:-2px; max-width:560px; }.descripcion { max-width:600px; }.hero-acciones { margin:24px 0; }.hero-visual { width:min(430px,100%); margin:auto; min-height:365px; }.tarjeta-demo { width:195px; }.tarjeta-atras { left:30px; top:48px; }.tarjeta-frente { right:28px; top:32px; }.etiqueta-flotante { top:0; left:0; }
  .pasos-inicio { grid-template-columns:1fr; gap:10px; }.seccion-intro { display:block; }.seccion-intro h2 { margin-top:8px; }.paso-inicio { padding:20px; }.paso-inicio p { font-size:13px; }.aviso-suave { align-items:flex-start; }
  .recorrido { margin:18px 20px 0; }.recorrido ol { padding:12px; gap:10px; justify-content:space-between; }.recorrido li { flex:1; flex-direction:column; gap:7px; font-size:9px; text-align:center; }.recorrido li:last-child { flex:1; }.recorrido li::after { display:none; }
  .datos-layout { grid-template-columns:1fr; }.datos-nota { padding:24px; }.datos-nota h2 { font-size:21px; }.formulario-datos { padding:22px; }.campos { gap:14px; }.carrera-opcion { padding:12px; }.carrera-icono { min-width:25px; height:25px; font-size:14px; }
  .texto-consentimiento { padding:24px; }.pie-panel { padding:20px 24px; }.titulo-pantalla { font-size:30px; }.subtitulo { font-size:13px; }
  .panel-pregunta { padding:22px 18px 0; }.pregunta-titulo { font-size:21px; }.opcion { min-height:76px; padding:14px 14px; font-size:16px; gap:12px; }.letra-opcion { width:36px; height:36px; font-size:15px; }.marca-elegida { font-size:11px; }.segmentos { gap:3px; }
  .paneles { grid-template-columns:1fr; }.panel-tarjeta { max-width:520px; width:100%; margin:auto; }.panel-trabajos { padding:24px; }.panel-trabajos h2 { font-size:25px; }
  .resultado-encabezado { align-items:flex-start; gap:15px; }.perfil-insignia { min-width:105px; padding:14px 12px; }.perfil-insignia strong { font-size:24px; }.perfil-insignia small { font-size:6px; letter-spacing:.6px; }.perfil-insignia>span { font-size:9px; max-width:95px; }.resultado-encabezado .titulo-pantalla { font-size:28px; }
  .resultado-cierre .acciones { width:100%; }.boton { padding:13px 16px; font-size:12px; }
}
@media (max-width:420px) {
  .hero h1 { font-size:39px; }.hero .sobrelinea { font-size:8px; }.hero-datos { gap:18px; }.hero-datos>div+div { padding-left:16px; }.hero-datos span { font-size:9px; }
  .hero-visual { min-height:340px; }.tarjeta-demo { width:172px; }.tarjeta-atras { left:13px; }.tarjeta-frente { right:13px; }.etiqueta-flotante { font-size:10px; }.etiqueta-ejemplo { font-size:8px; }
  .resultado-encabezado { flex-direction:column; }.perfil-insignia { transform:none; display:flex; align-items:center; gap:14px; width:100%; text-align:left; }.perfil-insignia strong { margin:0; }.perfil-insignia small { max-width:45px; }.perfil-insignia>span { max-width:none; margin-left:auto; }
  .acciones,.pie-panel { flex-wrap:wrap; }.acciones .boton,.pie-panel .boton { flex:1 1 130px; }.carreras-grid { grid-template-columns:1fr; }.carrera-opcion { min-height:54px; }.campos { grid-template-columns:1fr; }
}
'@
}
@{ Ruta = 'web/estatico/css/mejoras.css'; Original = 'E48AC64675A4B766C1134E7D39FC7010A7CB6CE83805D2C3430A275D8B5647A9'; Nuevo = '8AF1136C7828F325D94F6406FF840259469C7EDB347308E77908BB597F6BAFC3'; Contenido = @'
/* Movimiento discreto: no interrumpe la lectura ni las respuestas. */
.pantalla { animation:aparecer .32s ease-out both; }
.boton,.opcion,.carrera-opcion { transition:background-color .18s,border-color .18s,box-shadow .18s,transform .18s; }
.progreso-barra { transition:width .25s ease; }
.boton:active:not(:disabled) { transform:translateY(1px); }
.trabajo { animation:aparecer .35s ease-out both; }
.pregunta { animation:aparecer .25s ease-out both; }
.opcion:has(input:checked),.carrera-opcion:has(input:checked) { animation:elegir .22s ease-out; }
@keyframes elegir { 0% { transform:scale(.98); } 60% { transform:scale(1.012); } 100% { transform:none; } }.trabajo-2 { animation-delay:.06s; }.trabajo-3 { animation-delay:.12s; }
@media (hover:hover) {
  .boton:hover:not(:disabled) { transform:translateY(-2px); box-shadow:0 6px 16px #29244114; }
  .opcion:hover,.carrera-opcion:hover { border-color:#a999c3; }
  .tarjeta-frente:hover { transform:rotate(3deg) translateY(-4px); }
}
.tarjeta-frente { transition:transform .3s ease; }
@keyframes aparecer { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:none; } }
@media (prefers-reduced-motion:reduce) {
  *,*::before,*::after { animation:none !important; transition:none !important; scroll-behavior:auto !important; }
}
@media print {
  .cabecera,.recorrido,.pie-sitio,.acciones,.descargar,.registro { display:none; }
  body { background:white; }.contenido { padding:0; }.paneles { grid-template-columns:260px 1fr; }
}
'@
}
@{ Ruta = 'web/estatico/js/pantallas/cuestionario.js'; Original = 'FC8D2EB1EFD20F9F6C7CA9407E4535BFACEBBD418B5B7468D88BCD17DE42B6CB'; Nuevo = '318A780393FD3722A853A156C25963BFD889CC5082BBB487040257FA1A869866'; Contenido = @'
import { guardarSesion } from '../sesion.js';
import { calcularResultado } from '../api.js';
import { estado, preguntasFaltantes } from '../estado.js';
import { PREGUNTAS_POR_DIMENSION } from '../textos.js';
import { boton, el, panel, pantalla } from '../ui.js';

const TEMAS = ['Cómo te relacionas', 'Cómo descubres', 'Cómo decides', 'Cómo te organizas'];
const PISTAS = ['Piensa en cómo prefieres compartir tu tiempo y tu energía.', 'Piensa en qué suele llamar tu atención cuando conoces algo nuevo.', 'Piensa en qué te ayuda a elegir entre distintas posibilidades.', 'Piensa en cómo prefieres llevar tus planes y actividades.'];
const AVANCE_MS = 450;

// Una pregunta por pantalla: al tocar una opción se marca con fuerza y,
// tras un instante, se pasa sola a la siguiente.
export function mostrarCuestionario(contenedor, app) {
  const { preguntas } = app.catalogo;
  const total = preguntas.length;
  let actual = preguntasFaltantes(total)[0] ?? 0;
  let enviando = false;
  let reintento = false;
  let temporizador = null;

  const chip = el('span', { class: 'tema-chip' });
  const numero = el('p', { class: 'pregunta-numero', role: 'status', 'aria-live': 'polite' });
  const pista = el('p', { class: 'pista-grupo' });
  const cuerpo = el('div', { class: 'cuerpo-pregunta' });
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const segmentos = preguntas.map((_, i) => {
    const b = el('button', { type: 'button', class: 'segmento', 'aria-label': `Ir a la pregunta ${i + 1}` });
    b.addEventListener('click', () => ir(i));
    return b;
  });
  const anterior = boton('← Anterior', () => { if (actual > 0) ir(actual - 1); else app.ir('datos'); });
  const siguiente = boton('Siguiente →', continuar, 'primario');
  const vista = pantalla('cuestionario',
    el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, 'PASO 03 / TUS PREFERENCIAS'), el('h1', { class: 'titulo-pantalla' }, 'Aquí no hay respuestas incorrectas.'), el('p', { class: 'subtitulo' }, 'Toca la opción que más se parezca a ti, aunque ninguna te describa por completo.')),
    panel({ clase: 'panel-pregunta' },
      el('div', { class: 'cabecera-pregunta' }, chip, numero),
      el('div', { class: 'segmentos' }, segmentos),
      pista, cuerpo, aviso,
      el('div', { class: 'acciones pie-cuestionario' }, anterior, siguiente)));
  contenedor.append(vista);

  function marcadores() {
    const respondidas = total - preguntasFaltantes(total).length;
    numero.textContent = `Pregunta ${actual + 1} de ${total} · ${respondidas} respondidas`;
    segmentos.forEach((b, i) => {
      b.classList.toggle('hecha', Boolean(estado.respuestas[i]));
      b.classList.toggle('actual', i === actual);
      if (i === actual) b.setAttribute('aria-current', 'step'); else b.removeAttribute('aria-current');
      b.disabled = enviando;
    });
    anterior.textContent = actual === 0 ? '← Sobre ti' : '← Anterior';
    siguiente.textContent = actual < total - 1 ? 'Siguiente →' : reintento ? 'Reintentar mi resultado' : 'Descubrir mi perfil ✦';
  }

  function pintar(enfocar) {
    const p = preguntas[actual];
    const bloque = Math.floor(actual / PREGUNTAS_POR_DIMENSION);
    chip.textContent = TEMAS[bloque] ?? `Bloque ${bloque + 1}`;
    chip.dataset.bloque = String(bloque % 4);
    pista.textContent = PISTAS[bloque] ?? '';
    aviso.textContent = '';
    const titulo = el('legend', { class: 'pregunta-titulo', tabindex: '-1' }, p.pregunta);
    cuerpo.replaceChildren(el('fieldset', { class: 'pregunta', id: `bloque-${actual}` }, titulo,
      el('div', { class: 'opciones' }, ['A', 'B'].map((letra) => {
        const input = el('input', { type: 'radio', name: `pregunta-${actual}`, value: letra, checked: estado.respuestas[actual] === letra });
        // detail > 0: toque o clic. Con el teclado no se avanza solo, para poder comparar A y B.
        input.addEventListener('click', (evento) => elegir(letra, evento.detail > 0));
        return el('label', { class: 'opcion' }, input,
          el('span', { class: 'letra-opcion', 'aria-hidden': 'true' }, letra),
          el('span', { class: 'texto-opcion' }, p[letra]),
          el('span', { class: 'marca-elegida', 'aria-hidden': 'true' }, '✓ Elegida'));
      }))));
    marcadores();
    if (enfocar) {
      titulo.focus({ preventScroll: true });
      if (vista.getBoundingClientRect().top < 0) vista.scrollIntoView({ block: 'start' });
    }
  }

  function ir(nuevo, enfocar = true) {
    if (enviando) return;
    clearTimeout(temporizador);
    actual = nuevo;
    pintar(enfocar);
  }

  function elegir(letra, avanzarSolo) {
    if (enviando) return;
    estado.respuestas[actual] = letra;
    estado.resultado = null;
    aviso.textContent = '';
    guardarSesion('cuestionario');
    marcadores();
    clearTimeout(temporizador);
    if (avanzarSolo && actual < total - 1) {
      const desde = actual;
      temporizador = setTimeout(() => { if (vista.isConnected && !enviando && actual === desde) ir(desde + 1); }, AVANCE_MS);
    }
  }

  async function continuar() {
    if (enviando) return;
    if (actual < total - 1) {
      if (!estado.respuestas[actual]) {
        aviso.textContent = 'Toca una opción para continuar.';
        cuerpo.querySelector('input')?.focus();
        return;
      }
      ir(actual + 1);
      return;
    }
    const faltantes = preguntasFaltantes(total);
    if (faltantes.length) {
      ir(faltantes[0], false);
      aviso.textContent = `Todavía falta responder: ${faltantes.map((n) => n + 1).join(', ')}. Toca una opción para continuar.`;
      cuerpo.querySelector('input')?.focus();
      return;
    }
    enviar();
  }

  async function enviar() {
    clearTimeout(temporizador);
    enviando = true; marcadores();
    vista.querySelectorAll('button, input').forEach((n) => { n.disabled = true; });
    siguiente.textContent = 'Preparando tu perfil…'; siguiente.setAttribute('aria-busy', 'true');
    try {
      estado.registroId ||= crypto.randomUUID();
      guardarSesion('cuestionario');
      const resultado = await calcularResultado({ consentimiento: true, edad: Number(estado.edad), sexo: estado.sexo,
        carrera: estado.carrera, respuestas: preguntas.map((_, i) => estado.respuestas[i]), registro_id: estado.registroId });
      if (!vista.isConnected) return;
      estado.resultado = resultado;
      if (resultado.registro.guardado) estado.registroId = resultado.registro.id;
      app.ir('resultado');
    } catch (error) {
      if (!vista.isConnected) return;
      aviso.textContent = error.message;
      enviando = false; reintento = true;
      vista.querySelectorAll('button, input').forEach((n) => { n.disabled = false; });
      siguiente.removeAttribute('aria-busy');
      marcadores();
    }
  }

  pintar(false);
}
'@
}
@{ Ruta = 'web/estatico/js/pantallas/datos.js'; Original = '093286E09975269D401E3781CCDFA6738CBAA51B8F89098F4F791F0F7F4E2972'; Nuevo = '4A2F0187A74BAC85A2E3664EC65F393D3E97A870BE5ADC48B91ACEFFE09E0C8B'; Contenido = @'
import { EDAD_MAXIMA, EDAD_MINIMA, SEXOS, datosCompletos, estado } from '../estado.js';
import { boton, el, panel, pantalla } from '../ui.js';
import { FACULTAD, etiquetaCarrera, iconoCarrera, ordenarCarreras } from '../carreras.js';

function selector(clave, etiqueta, opciones) {
  const select = el('select', { id: clave, required: true },
    el('option', { value: '', disabled: true }, 'Selecciona una opción'),
    opciones.map((valor) => el('option', { value: valor }, valor)));
  select.value = estado[clave];
  select.addEventListener('change', () => { estado[clave] = select.value; estado.resultado = null; });
  return el('div', { class: 'campo' }, el('label', { for: clave }, `${etiqueta} *`), select);
}

export function mostrarDatos(contenedor, app) {
  const edades = Array.from({ length: EDAD_MAXIMA - EDAD_MINIMA + 1 }, (_, i) => String(EDAD_MINIMA + i));
  const aviso = el('p', { class: 'aviso', role: 'alert' });
  const carreras = ordenarCarreras(app.catalogo.carreras).map((carrera) => el('label', { class: 'carrera-opcion' },
    el('input', { type: 'radio', name: 'carrera', value: carrera, checked: estado.carrera === carrera,
      onchange: () => { estado.carrera = carrera; estado.resultado = null; } }),
    el('span', { class: 'carrera-icono', 'aria-hidden': 'true' }, iconoCarrera(carrera)),
    el('span', { class: 'carrera-nombre' }, etiquetaCarrera(carrera))));
  const continuar = () => {
    if (datosCompletos(app.catalogo.carreras)) app.ir('cuestionario');
    else {
      aviso.textContent = 'Completa tu edad, sexo y carrera para continuar.';
      const pendiente = !estado.edad ? '#edad' : !estado.sexo ? '#sexo' : 'input[name="carrera"]';
      contenedor.querySelector(pendiente)?.focus();
    }
  };
  contenedor.append(pantalla('datos',
    el('div', { class: 'encabezado-pagina' }, el('p', { class: 'sobrelinea' }, 'PASO 02 / SOBRE TI'), el('h1', { class: 'titulo-pantalla' }, 'Hagámoslo más personal.'), el('p', { class: 'subtitulo' }, 'Tu carrera nos ayuda a mostrarte áreas profesionales que tengan sentido para ti.')),
    el('div', { class: 'datos-layout' }, panel({ clase: 'formulario-datos' },
      el('div', { class: 'campos' }, selector('edad', 'Edad', edades), selector('sexo', 'Sexo', SEXOS)),
      el('fieldset', { class: 'carreras' }, el('legend', {}, '¿Qué carrera estudias? *'), el('p', { class: 'facultad' }, FACULTAD), el('div', { class: 'carreras-grid' }, carreras)),
      aviso,
      el('div', { class: 'acciones' }, boton('← Volver', () => app.ir('consentimiento')), boton('Ir a las preguntas →', continuar, 'primario'))),
      el('aside', { class: 'datos-nota' }, el('span', { class: 'icono-grande', 'aria-hidden': 'true' }, '✦'), el('h2', {}, 'Tu perfil empieza con tus respuestas.'), el('p', {}, 'La IA utiliza únicamente las 20 respuestas del cuestionario. Tu edad, sexo y carrera no cambian el perfil calculado.'), el('p', {}, 'La carrera se utiliza después para elegir tres áreas de trabajo que puedes explorar.'), el('span', { class: 'mini-pill' }, 'Sin nombres ni correos')))));
}
'@
}
@{ Ruta = 'web/estatico/js/pantallas/resultado.js'; Original = '990E526ED2D0528B5F10CBDBBDEDCEF463D32DE240EBFA50BE40631D8F95D16F'; Nuevo = '48218C6D28DD3B0F469A2A021F9C0A97C4C6F664D9E53C5D64580C5D0212EA16'; Contenido = @'
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
'@
}
@{ Ruta = 'web/estatico/js/carreras.js'; Original = ''; Nuevo = '942A7BE4E98FCEC2179FFB4421CCABE05233C14EC81C6E6FE284C308C925275B'; Contenido = @'
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
'@
}
@{ Ruta = 'REDISENO_WEB.md'; Original = 'F49206085C3C16481EE54E110989FF1869E8FDB81F84C0F1C88BF9C30217A063'; Nuevo = '1B84C83006AE3FE65695EB7FC136C0D2058610DF1EBA27912F48941960B648CA'; Contenido = @'
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

'@
}
 )
# Primero verifica todos los destinos. No sobrescribe cambios desconocidos.
foreach ($Archivo in $Archivos) {
    $Ruta = Join-Path $Raiz $Archivo.Ruta
    if (Test-Path -LiteralPath $Ruta) {
        if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) { throw "No es un archivo: $Ruta" }
        $Hash = (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash
        $Normalizado = Hash-Texto ([System.IO.File]::ReadAllText($Ruta).Replace("`r`n", "`n"))
        if ($Hash -ne $Archivo.Original -and $Hash -ne $Archivo.Nuevo -and $Normalizado -ne $Archivo.Original -and $Normalizado -ne $Archivo.Nuevo) { throw "Cambios desconocidos en $Ruta. No se modificó nada." }
    } elseif ($Archivo.Original) { throw "Falta el archivo original $Ruta. No se modificó nada." }
}
foreach ($Archivo in $Archivos) {
    $Ruta = Join-Path $Raiz $Archivo.Ruta
    if ((Test-Path -LiteralPath $Ruta) -and (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash -eq $Archivo.Nuevo) { continue }
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($Ruta)) | Out-Null
    $Texto = ($Archivo.Contenido -replace "`r`n", "`n") + "`n"
    [System.IO.File]::WriteAllText($Ruta, $Texto, $Utf8)
    if ((Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash -ne $Archivo.Nuevo) { throw "No coincide la verificación de $Ruta" }
    Write-Host "Actualizado: $($Archivo.Ruta)"
}
Write-Host 'Ajustes aplicados. Revisa los cambios en VS Code y sincroniza con GitHub. Consulta REDISENO_WEB.md.'
