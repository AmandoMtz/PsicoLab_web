from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import json,math
ROOT=Path(__file__).resolve().parent
profiles={int(k):v for k,v in json.loads((ROOT/'datos/perfiles_1_16.json').read_text(encoding='utf-8')).items()}
F='/usr/share/fonts/truetype/dejavu/DejaVuSans'
FB='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
FR='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
labels={
'ENFJ':('Coordinación y escucha','Colaboración · visión compartida'), 'ENFP':('Ideas y posibilidades','Creatividad · conexión'),
'ENTJ':('Organización estratégica','Planificación · decisiones'), 'ENTP':('Exploración de ideas','Debate · alternativas'),
'ESFJ':('Apoyo y coordinación','Trabajo conjunto · seguimiento'), 'ESFP':('Experiencias compartidas','Acción · comunicación'),
'ESTJ':('Procesos y resultados','Orden · decisiones prácticas'), 'ESTP':('Resolución dinámica','Adaptación · respuesta'),
'INFJ':('Sentido y reflexión','Perspectiva · escucha'), 'INFP':('Valores y creatividad','Expresión · posibilidades'),
'INTJ':('Pensamiento estratégico','Análisis · planificación'), 'INTP':('Análisis y curiosidad','Preguntas · exploración'),
'ISFJ':('Cuidado y seguimiento','Atención · constancia'), 'ISFP':('Expresión personal','Creatividad · sensibilidad'),
'ISTJ':('Detalle y estructura','Precisión · método'), 'ISTP':('Análisis aplicado','Observación · soluciones'),
}
out=ROOT/'assets';out.mkdir(exist_ok=True)
colors=[('#333268','#745BB9'),('#214A72','#3D8FBB'),('#354A5F','#708A95'),('#654172','#BE6B9A')]
def font(size,bold=False):return ImageFont.truetype(FB if bold else FR,size)
for idx,code in profiles.items():
 w,h=840,510
 c1,c2=colors[(idx-1)%4]
 # Gradient using repeated 1-px lines
 a=tuple(int(c1[i:i+2],16) for i in (1,3,5));b=tuple(int(c2[i:i+2],16) for i in (1,3,5))
 im=Image.new('RGB',(w,h)); draw=ImageDraw.Draw(im)
 for y in range(h):
  t=y/h;rgb=tuple(int(a[k]*(1-t)+b[k]*t) for k in range(3));draw.line([(0,y),(w,y)],fill=rgb)
 draw.ellipse((595,-125,1070,350),outline=(255,255,255),width=4)
 draw.ellipse((630,-90,1020,300),outline=(180,200,245),width=4)
 draw.ellipse((-160,350,320,830),outline=(210,215,245),width=3)
 draw.rounded_rectangle((48,45,440,101),radius=25,fill='#FFFFFF')
 draw.text((72,57),'PSICOLAB · PERFIL EXPLORATORIO',fill='#3A346F',font=font(17,True))
 draw.text((50,145),code,fill='white',font=font(119,True),stroke_width=1)
 title,desc=labels[code]
 draw.text((56,300),title,fill='white',font=font(35,True))
 draw.text((58,361),desc,fill='#E3E9FF',font=font(24))
 draw.rectangle((51,430,790,432),fill='#B6C2F4')
 draw.text((55,455),f'Tipo {idx:02d} de 16  ·  Preferencias declaradas, no diagnóstico',fill='#EFF2FF',font=font(18))
 im.save(out/f'{code}.png',optimize=True)
print('Tarjetas generadas:',len(list(out.glob('*.png'))))
