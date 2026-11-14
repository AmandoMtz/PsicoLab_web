"""Prueba integral Tkinter con datos de ensayo, aislados del perfil del usuario."""
from pathlib import Path
import sys
from PIL import ImageGrab
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from app_psicolab import App, BLUE_READY, BLUE_LIGHT
from storage import records, database_path

app=App()
app.geometry('1160x850+0+0');app.update()
assert app.mode=='welcome'
assert not database_path().exists()
out=Path(__file__).resolve().parents[1]/'capturas'
out.mkdir(exist_ok=True)
ImageGrab.grab(bbox=(0,0,1160,850)).save(out/'Inicio_2.0.png')
app.consent_screen();app.update()
assert app.mode=='consent'
ImageGrab.grab(bbox=(0,0,1160,850)).save(out/'Consentimiento_2.0.png')
app.deny_consent();app.update()
assert app.mode=='declined' and not database_path().exists()
app.consent_screen();app.accept_consent();app.update()
assert app.mode=='demographics'
app._start_questionnaire();assert app.mode=='demographics'
app.age.set('20');app.sex.set('Femenino');app.career.set('Derecho')
ImageGrab.grab(bbox=(0,0,1160,850)).save(out/'Datos_Generales_2.0.png')
app._start_questionnaire();app.update()
assert app.mode=='questionnaire'
assert len(app.qs)==20
assert app.next.cget('bg')==BLUE_LIGHT
for i in range(19):app.answers[i].set('A' if i%2 else 'B')
app.result();app.update()
assert app.mode=='questionnaire'
assert '20' in app.warning.cget('text')
app.answers[-1].set('A');app.update()
assert app.next.cget('bg')==BLUE_READY
ImageGrab.grab(bbox=(0,0,1160,850)).save(out/'Cuestionario_2.0.png')
app.result();app.update()
assert app.mode=='result' and app.result_value.number in range(1,17)
assert app.image_ref.width()>150
assert len(records())==1
assert records()[0]['edad']==20 and records()[0]['sexo']=='Femenino'
assert app.record_id
ImageGrab.grab(bbox=(0,0,1160,850)).save(out/'Resultado_2.0.png')
app.questionnaire();app.update()
assert app.mode=='questionnaire' and app.next.cget('bg')==BLUE_READY
app.result();app.update()
assert len(records())==1
from tkinter import messagebox
messagebox.askyesno=lambda *a,**kw:True
app.erase();app.update()
assert len(records())==0
assert app.record_id is None
assert app.mode=='result'
app.restart();app.update()
assert app.mode=='welcome' and app.age.get()=='' and app.sex.get()==''
assert all(v.get()=='' for v in app.answers)
app.destroy()
print('GUI OK: bienvenida, consentimiento, datos obligatorios, 20 preguntas, resultado, borrado')
