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
