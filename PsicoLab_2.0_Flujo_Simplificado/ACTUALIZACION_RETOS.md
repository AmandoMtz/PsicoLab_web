# Actualización: retos y correcciones de las capturas

Preparada a partir de `PsicoLab_web-main(2).zip`, la aplicación de escritorio `PsicoLab_2_0(1).zip` y las seis imágenes del ZIP de WhatsApp. No se ha publicado en GitHub ni desplegado en Render desde esta sesión.

## Publicar esta actualización

1. En Supabase, abre **SQL Editor**, crea una consulta, pega el contenido completo de **SUPABASE_RETOS.sql** y pulsa **Run**. Esto crea `public.retos`; conserva las respuestas existentes. Si aparece un error, resuélvelo antes de desplegar. No cambies las columnas de `respuestas`.
2. Extrae el ZIP de actualización. Dentro de **Para_GitHub** está la carpeta **PsicoLab_2.0_Flujo_Simplificado**, que contiene los archivos nuevos y modificados. En la raíz de `AmandoMtz/PsicoLab_web`, donde ya existe esa carpeta, elige **Add file → Upload files** y arrastra esa carpeta completa desde `Para_GitHub`. Confirma que las rutas comiencen con `PsicoLab_2.0_Flujo_Simplificado/` una sola vez. Guarda el commit. No borres la carpeta existente: estos archivos se combinan con los anteriores.
3. Conserva en Render las variables **SUPABASE_URL** y **SUPABASE_SECRET_KEY** que ya funcionan. No coloques claves en GitHub. Si el despliegue automático está activo, espera a que termine; de lo contrario usa **Manual Deploy → Deploy latest commit** en el servicio PsicoLab_web.
4. Comprueba `https://psicolab-web.onrender.com/api/salud` y después `https://psicolab-web.onrender.com/api/retos/salud`. La segunda ruta debe devolver `{"estado":"listo","modelo":"B3","retos":3}`. Si falla, comprueba que se ejecutó el SQL y que los tres archivos `modelos/retos_B3_reto*.joblib` se subieron.
5. Recarga la web con **Ctrl+F5**, completa un cuestionario de prueba, abre **¡Ahora, un reto!**, responde las tres situaciones y comprueba la comparación. En Supabase → **Table Editor → retos** verás `registro_id`, `pred_b3`, `decisiones` y `coincidencias`. `registro_id` enlaza con el cuestionario de `respuestas`. Esta comprobación real sigue pendiente.

Los archivos de `Para_GitHub` son una actualización parcial, no un proyecto independiente. No se necesita instalar dependencias nuevas ni modificar el comando de arranque de Render.

## Actualizar también tu copia local (opcional)

Si vas a publicar usando tu proyecto local en lugar de la carpeta preparada, copia `Actualizar_PsicoLab_Retos.ps1` junto a `psicolab_core.py` y ejecuta:

```powershell
cd "C:\Users\elnoo\Downloads\PsicoLab_web-main\PsicoLab_web-main\PsicoLab_2.0_Flujo_Simplificado"
powershell -ExecutionPolicy Bypass -File .\Actualizar_PsicoLab_Retos.ps1
```

Ajusta la ruta si tu carpeta tiene otro nombre. El script valida todos los archivos antes de escribir y hace un respaldo temporal. Si detecta una versión diferente a la del ZIP recibido, se detiene sin cambios: no fuerces la actualización sin comparar las versiones. Después publica los archivos modificados de tu copia local. El script no accede a Supabase, no ejecuta el SQL y no publica en GitHub.

## Cambios incluidos

- Se conserva el perfil y se añade **¡Ahora, un reto!** como segunda etapa, tal como en escritorio: introducción, tres situaciones A/B/C y comparación final.
- Se incorporan los tres modelos B3 originales del ZIP de escritorio y sus funciones de preparación de variables, sin reentrenarlos. El perfil sigue calculándose con el modelo MLP original.
- Las predicciones se calculan en el servidor con el cuestionario guardado y se registran antes de recibir las elecciones. No se envían al navegador hasta terminar. Un reintento conserva el mismo intento; si cambian las respuestas del cuestionario se crea otro intento con su propia copia de las entradas.
- Se permite recuperar el avance parcial de retos en la misma pestaña. Las respuestas definitivas no se pueden cambiar después de revelar las predicciones.
- La tabla `retos` tiene RLS activado y acceso del servidor mediante la clave secreta. Borrar un cuestionario por la API también elimina sus retos asociados.
- Se aplican las correcciones de las seis imágenes: «Decide participar», «Consentimiento de participación», «Estimado(a) participante:», «Género de nacimiento», «Tu resultado» y el aviso del modelo en el lugar indicado. Se alineó a la izquierda «Un recorrido pensado para ti» y se retiraron los textos tachados, las pistas de grupos, el pie técnico de la tarjeta, el bloque «Cómo se obtuvo este resultado» y «Mis datos».
- La interfaz no muestra mensajes de guardado exitoso en Supabase ni códigos de registro. Los errores de guardado siguen siendo visibles para no indicar éxito cuando no se guardó.

Los retos necesitan Supabase configurado y una ventana de guardado activa, igual que el cuestionario. Las variables de fechas existentes no se cambian. La aplicación de escritorio y sus datos SQLite no se modifican.

## Verificación realizada

- **86 pruebas Python aprobadas**, incluyendo los modelos originales, API, errores, guardado, reintentos, predicciones ocultas y cambios de cuestionario.
- Comprobación de sintaxis de los módulos JavaScript.
- Recorrido automatizado en DOM con el servidor local y almacenamiento simulado: inicio, consentimiento, datos, 20 respuestas, perfil, 3 retos, comparación, reentrada y recuperación de sesión.
- No se insertaron datos de prueba en tu Supabase real. La comprobación visual en navegador y celular y el guardado real tras el despliegue quedan pendientes; el navegador de este entorno no permitió previsualizar el servidor local.

Para repetir las pruebas con las dependencias del proyecto: `python -m pytest -q` desde la carpeta que contiene `psicolab_core.py`.
