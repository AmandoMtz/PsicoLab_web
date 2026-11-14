"""Fuente editorial: PsicoLab, cuestionario exploratorio de preferencias de 20 reactivos, versión revisada.
El usuario suministró una versión ajustada, cuyos enunciados originales no fueron recuperables
como archivo descargable en este entorno. Verificar redacción antes de uso institucional.
"""
import json
from pathlib import Path
P=Path(__file__).resolve().parent/'datos'
content=[
('Cuando estás en una reunión con personas que conoces poco, normalmente prefieres:','Integrarte a las conversaciones desde el principio.','Familiarizarte con el ambiente antes de participar en una conversación.'),
('Después de pasar varias horas interactuando con otras personas, generalmente prefieres:','Dedicar un tiempo a actividades individuales.','Continuar compartiendo tiempo con otras personas.'),
('Cuando tienes una idea interesante, generalmente prefieres:','Conversar sobre ella mientras organizas tus pensamientos.','Organizar tus pensamientos antes de conversar sobre ella.'),
('Cuando participas en una actividad nueva que te interesa, prefieres:','Explorarla por tu cuenta antes de compartir la experiencia.','Explorarla interactuando con otras personas.'),
('Cuando participas en un equipo nuevo, prefieres:','Intercambiar ideas desde el inicio para conocer al grupo.','Escuchar las primeras propuestas antes de compartir tus ideas.'),
('Cuando comienzas a aprender un tema nuevo, prefieres:','Revisar ejemplos específicos para comprender cómo funciona.','Conocer primero las ideas generales que explican el tema.'),
('Cuando analizas un problema que no conoces, primero prefieres:','Identificar relaciones y patrones que puedan explicar el problema.','Identificar la información disponible y los aspectos específicos del problema.'),
('Cuando alguien te explica un proyecto, te interesa conocer primero:','Los datos específicos y las características de lo que se propone.','Las ideas centrales y las posibilidades que plantea.'),
('Cuando recibes información sobre un tema, generalmente prefieres:','Identificar patrones y relaciones entre las ideas.','Examinar los datos y ejemplos que se presentan.'),
('Cuando buscas comprender una situación compleja, prefieres:','Explorar distintas interpretaciones y conexiones posibles.','Examinar los hechos y ejemplos disponibles.'),
('Cuando debes elegir entre dos alternativas importantes, normalmente das mayor peso a:','La consistencia de los criterios utilizados para compararlas.','La congruencia de la elección con tus valores personales.'),
('Cuando existen diferentes opiniones en un equipo, para decidir qué hacer prefieres:','Considerar cómo cada propuesta afectaría a las personas involucradas.','Comparar las propuestas utilizando criterios previamente acordados.'),
('Cuando debes recomendar una solución ante una situación que afecta a varias personas, prefieres basar tu recomendación principalmente en:','Criterios que puedan aplicarse de manera consistente.','Las necesidades particulares de las personas involucradas.'),
('Cuando colaboras en una decisión de grupo y las alternativas tienen ventajas similares, prefieres dar prioridad a:','La alternativa más congruente con los valores compartidos por el grupo.','La alternativa que mejor cumple los criterios establecidos.'),
('Cuando dos propuestas parecen igualmente viables, prefieres:','Seleccionar la que mejor cumple criterios previamente definidos.','Seleccionar la que mejor considera las necesidades y valores involucrados.'),
('Al comenzar un proyecto, te resulta más cómodo:','Definir una estructura inicial para organizar las actividades.','Mantener varias alternativas de organización mientras avanzas.'),
('Cuando realizas un viaje, generalmente prefieres:','Elegir las actividades durante el viaje según las circunstancias.','Llevar un itinerario con las actividades previstas.'),
('Cuando tienes varias actividades por realizar, te resulta más cómodo:','Seguir una secuencia de actividades previamente definida.','Alternar entre actividades según las necesidades del momento.'),
('Cuando cambia inesperadamente una actividad que tenías prevista, prefieres:','Decidir cómo continuar conforme cambia la situación.','Establecer un nuevo plan para continuar.'),
('Cuando comienzas una actividad que admite varias formas de realizarse, prefieres:','Ajustar el procedimiento conforme descubres nuevas posibilidades.','Definir los pasos principales antes de comenzar.'),
]
pa=list('EIEIE'+'SNSNN'+'TFTFT'+'JPJPP')
pb=list('IEIEI'+'NSNSS'+'FTFTF'+'PJPJJ')
assert len(content)==20 and len(pa)==20 and len(pb)==20
questions=[{'id':i,'dimension':['E/I','S/N','T/F','J/P'][(i-1)//5],'question':q,'A':a,'B':b,'pole_A':pa[i-1],'pole_B':pb[i-1]} for i,(q,a,b) in enumerate(content,1)]
(P/'preguntas_20.json').write_text(json.dumps(questions,ensure_ascii=False,indent=2),encoding='utf-8')
codes=[a+b+c+d for a in 'EI' for b in 'NS' for c in 'FT' for d in 'JP']
# Los IDs siguen el orden observado en la etiqueta del CSV, no el orden alfabético de las clases.
assert codes==['ENFJ','ENFP','ENTJ','ENTP','ESFJ','ESFP','ESTJ','ESTP','INFJ','INFP','INTJ','INTP','ISFJ','ISFP','ISTJ','ISTP']
(P/'perfiles_1_16.json').write_text(json.dumps({str(i):v for i,v in enumerate(codes,1)},ensure_ascii=False,indent=2),encoding='utf-8')

roles={
'Derecho':[
('Asesoría y análisis contractual','ISTJ','Examinar contratos, normas y documentación de acuerdos.'),
('Litigio y argumentación','ENTP','Construir argumentos y analizar distintas interpretaciones.'),
('Mediación y conciliación','ENFJ','Facilitar conversaciones y orientar acuerdos entre partes.'),
('Investigación jurídica','INTP','Estudiar jurisprudencia, doctrina y problemas jurídicos.'),
('Cumplimiento normativo','ESTJ','Organizar procesos legales y supervisar requisitos regulatorios.'),
('Derechos humanos','INFP','Apoyar proyectos de promoción, defensa y divulgación de derechos.'),
('Políticas públicas','INTJ','Evaluar regulaciones y diseñar propuestas institucionales.'),
('Relaciones institucionales','ESFJ','Coordinar interlocución y programas de información legal.'),
('Asistencia jurídica comunitaria','ISFJ','Acompañar procesos de orientación, trámites y seguimiento.'),
('Gestión de asuntos jurídicos','ESTP','Atender procesos y resolver incidencias operativas.'),
],
'Comunicación':[
('Redacción y edición','INFP','Desarrollar y revisar textos para distintos públicos.'),
('Comunicación organizacional','ESTJ','Coordinar mensajes internos y planes de comunicación.'),
('Relaciones públicas','ENFJ','Organizar vocerías, redes de colaboración y eventos.'),
('Periodismo de investigación','INTP','Verificar fuentes y analizar información para reportajes.'),
('Producción audiovisual','ISFP','Crear materiales audiovisuales y narrativas visuales.'),
('Estrategia de contenidos','ENFP','Diseñar campañas y conectar ideas con audiencias.'),
('Analítica de audiencias','INTJ','Interpretar datos de comunicación para mejorar contenidos.'),
('Gestión de comunidades','ESFJ','Facilitar conversaciones y proyectos con comunidades.'),
('Cobertura de eventos','ESFP','Comunicar experiencias y generar contenido en directo.'),
('Comunicación de crisis','ENTJ','Coordinar respuestas y mensajes bajo presión.'),
],
'Turismo':[
('Operación hotelera','ESTJ','Organizar servicios y procesos de alojamiento.'),
('Guía cultural y de visitantes','ESFP','Acompañar recorridos y compartir contexto cultural.'),
('Planeación de destinos','INTJ','Analizar flujos turísticos y elaborar planes de desarrollo.'),
('Diseño de experiencias turísticas','ENFP','Crear recorridos y experiencias para diferentes públicos.'),
('Turismo sostenible','INFP','Proponer actividades sensibles al patrimonio y entorno.'),
('Logística de viajes','ISTJ','Coordinar itinerarios, reservas y proveedores.'),
('Atención a huéspedes','ESFJ','Resolver solicitudes y mejorar la experiencia de visitantes.'),
('Investigación turística','INTP','Estudiar tendencias, mercados y patrones de viaje.'),
('Coordinación de grupos','ENFJ','Facilitar actividades de grupos y equipos de servicio.'),
('Operación en campo','ESTP','Atender imprevistos y ajustar actividades rápidamente.'),
],
'Psicología':[
('Investigación psicológica','INTP','Plantear estudios, interpretar literatura y analizar datos.'),
('Psicología educativa','ENFJ','Participar en estrategias de aprendizaje y acompañamiento.'),
('Proyectos comunitarios','INFJ','Diseñar programas de bienestar y apoyo comunitario.'),
('Desarrollo organizacional','ENTJ','Colaborar en iniciativas de clima y desarrollo de equipos.'),
('Evaluación y medición','ISTJ','Aplicar protocolos validados bajo supervisión competente.'),
('Divulgación preventiva','ENFP','Crear materiales de promoción del bienestar.'),
('Apoyo psicoeducativo','ISFJ','Colaborar en orientación educativa dentro del ámbito autorizado.'),
('Evaluación de programas','INTJ','Examinar resultados e indicadores de intervenciones.'),
('Trabajo grupal','ESFJ','Facilitar actividades y proyectos de apoyo entre pares.'),
('Divulgación científica','INFP','Comunicar investigaciones a públicos no especializados.'),
],
'Inglés':[
('Docencia del inglés','ENFJ','Diseñar experiencias de aprendizaje del idioma.'),
('Traducción escrita','ISTJ','Revisar terminología y traducir documentos.'),
('Interpretación bilingüe','ENTP','Facilitar el intercambio de mensajes entre idiomas.'),
('Edición de materiales bilingües','INTP','Revisar contenido y coherencia de textos en inglés.'),
('Comunicación internacional','ENFP','Elaborar contenidos para públicos interculturales.'),
('Materiales didácticos','INFJ','Diseñar recursos para enseñanza de lenguas.'),
('Coordinación académica','ESTJ','Administrar cursos y proyectos educativos.'),
('Localización de contenidos','ISFP','Adaptar mensajes culturales para diferentes mercados.'),
('Experiencias interculturales','ESFP','Guiar visitantes e intercambiar información cultural.'),
('Atención bilingüe','ESFJ','Acompañar usuarios en servicios multilingües.'),
],
'Economía y Finanzas':[
('Análisis financiero','INTJ','Analizar indicadores y construir escenarios financieros.'),
('Auditoría y control','ISTJ','Revisar registros y fortalecer controles internos.'),
('Planeación presupuestal','ESTJ','Organizar presupuestos y dar seguimiento a resultados.'),
('Investigación económica','INTP','Analizar datos e interpretar tendencias económicas.'),
('Educación financiera','ENFJ','Explicar conceptos económicos a diferentes públicos.'),
('Gestión de riesgos','ISFJ','Ayudar a documentar controles y riesgos operativos.'),
('Emprendimiento y modelos de negocio','ENTP','Explorar proyectos y evaluar oportunidades comerciales.'),
('Comunicación económica','ENFP','Traducir temas económicos a materiales divulgativos.'),
('Atención de servicios financieros','ESFJ','Acompañar consultas sobre productos y procesos.'),
('Operación financiera','ESTP','Coordinar actividades financieras de respuesta rápida.'),
],
}
(P/'areas_profesionales.json').write_text(json.dumps({k:[{'titulo':a,'preferencias_ilustrativas':b,'actividades':c} for a,b,c in items] for k,items in roles.items()},ensure_ascii=False,indent=2),encoding='utf-8')
print('Generated',len(questions),'questions',len(codes),'profiles',len(roles),'careers')
