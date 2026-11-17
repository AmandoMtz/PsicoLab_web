# Conectar PsicoLab con Supabase

La web utiliza Supabase cuando SUPABASE_URL o SUPABASE_SECRET_KEY están definidas.
Una configuración incompleta informa el error y nunca guarda silenciosamente en SQLite.
Sin ambas variables, conserva el comportamiento anterior de SQLite.
No se añaden dependencias. El núcleo, modelo, diseño y almacenamiento de escritorio no cambian.

## Configuración
1. Crear public.respuestas con el SQL proporcionado en la conversación. Activar RLS y conceder
SELECT, INSERT, UPDATE, DELETE únicamente a service_role. Mantener Data API habilitada.
2. Supabase > Settings > API Keys: crear/copiar una Secret key sb_secret_.
No usar publishable, anon, la contraseña de PostgreSQL ni una clave legacy en esta versión.
3. Render > Environment:
SUPABASE_URL = URL HTTPS del proyecto (copiar de Supabase; sin /rest/v1).
SUPABASE_SECRET_KEY = clave sb_secret_ (solo en Render, nunca en GitHub).
4. Para registrar sin restricción temporal, eliminar PSICOLAB_GUARDAR_DESDE y
PSICOLAB_GUARDAR_HASTA en Render. Si se mantienen, se respeta el horario configurado.
Si gestionas Render mediante Blueprint, elimina también esas dos entradas en render.yaml
para que una sincronización no restablezca las fechas. Este actualizador no cambia el horario.
PSICOLAB_DATA_DIR no es necesario con Supabase; no contratar disco.
5. Subir los cambios del actualizador a GitHub y esperar el despliegue en Render.
6. /api/salud debe mostrar almacenamiento: listo (Supabase).
Este chequeo verifica lectura y conexión; la prueba del cuestionario verifica escritura.
7. Contestar un cuestionario de prueba y comprobar Registro consentido guardado en Supabase.
En Supabase > Table Editor > respuestas debe aparecer una fila. Revisar respuestas debe
actualizar el mismo ID; Eliminar registro debe quitarlo. No uses respuestas de prueba como datos reales.

## Consultar y exportar
Usar Table Editor > respuestas o SQL Editor en el panel privado de Supabase.
Ejemplo: SELECT * FROM public.respuestas ORDER BY fecha DESC;
Exportar el resultado como CSV desde el panel y abrirlo en Excel.
Los comandos de investigacion.py siguen leyendo SQLite LOCAL: no consultan Supabase.
No hay ruta pública para listar/exportar las respuestas.

## Diagnóstico
HTTP 401: clave incorrecta; HTTP 403: revisar GRANT de service_role;
HTTP 404: tabla, esquema public y Data API; HTTP 400: revisar estructura de tabla.
Las fechas pueden bloquear el guardado aunque la conexión esté lista.
La clave secreta no se muestra en errores ni se envía al navegador.
Las respuestas anteriores que nunca se guardaron no se recuperan con este cambio.

## Alcance
La autenticación de participantes conserva el UUID aleatorio que ya usaba la aplicación.
El servidor conserva el control de consentimientos y la ventana de registro.
No se han usado credenciales reales ni se ha accedido a la base remota del usuario.
Pruebas automatizadas con API Supabase simulada; verificar la integración real tras configurar Render.
