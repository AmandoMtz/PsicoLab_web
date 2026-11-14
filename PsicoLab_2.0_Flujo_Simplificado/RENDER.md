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
