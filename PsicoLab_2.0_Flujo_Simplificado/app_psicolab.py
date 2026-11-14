#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PsicoLab 2.0: inicio -> consentimiento -> datos -> 20 reactivos -> resultado IA.

La red MLP usa exclusivamente R01...R20. Edad/sexo/carrera NO son entradas de la IA.
Las etiquetas y confianza softmax de los datos sintéticos no son diagnósticos.
"""
from __future__ import annotations
import tkinter as tk
from tkinter import ttk, messagebox
from PIL import Image, ImageTk
from psicolab_core import ROOT, questions, predict_ai, career_areas, careers
from version import VERSION, ALLOW_REAL_STORAGE

BG='#ECECEC'; WHITE='#FFFFFF'; NAVY='#1F2540'; YELLOW='#F7D500'
PINK='#F28AC2'; PINK_LIGHT='#FCE0EF'; ORANGE='#FF6A33'
BLUE_READY='#1E73E8'; BLUE_ACTIVE='#175FC1'; BLUE_LIGHT='#D9E9FF'
GREEN='#08B850'; GREEN_LIGHT='#D9F8E6'; MUTED='#737373'; LINE='#D9D9D9'
SUCCESS='#0D8F46'; WARNING='#C94A2E'
JOB_BOX=[(PINK_LIGHT,PINK),('#FFE1D6',ORANGE),(GREEN_LIGHT,GREEN)]
CONSENT_TITLE='Consentimiento informado para participar en PsicoLab'
CONSENT_TEXT=(
 'Estimado(a) estudiante:\n\n'
 'Se te invita a participar en PsicoLab, una plataforma orientada a la evaluación y el análisis '
 'de aspectos psicológicos con fines académicos e institucionales.\n\n'
 'Tu participación es voluntaria y la información que proporciones será tratada de manera '
 'confidencial. Los datos recopilados podrán almacenarse de forma anonima, sin información que permita '
 'identificarte personalmente, para su posible utilización en investigaciones académicas, '
 'análisis estadísticos, proyectos educativos o actividades institucionales.\n\n'
 'Los resultados podrán utilizarse de manera individual cuando corresponda a la evaluación y de forma  '
 'agrupada y anónima para otros fines académicos o institucionales, respetando en todo momento la '
 'privacidad de los participantes. Al aceptar, confirmas que has leído y comprendido esta información y '
 'que autorizas voluntariamente tu participación en PsicoLab, así como el almacenamiento y posible uso futuro '
 'de tus datos anonimizados para los fines mencionados.\n\n'
 '¿Aceptas participar en PsicoLab y autorizas el uso anonimo de tus datos para fines '
 'académicos o institucionales?'
)

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title(f'PsicoLab {VERSION} | ¿Puede un algoritmo conocerte?')
        self.geometry('1160x850'); self.minsize(960,690)
        self.configure(bg=BG)
        self.qs=questions()
        self.answers=[tk.StringVar(value='') for _ in range(20)]
        self.age=tk.StringVar(value='')
        self.sex=tk.StringVar(value='')
        self.career=tk.StringVar(value='')
        self.consent=False
        self.record_id=None
        self.status_text=''
        self.mode='welcome'
        self.canvas=None
        self.image_ref=None
        self._style(); self._shell()
        for v in self.answers:
            v.trace_add('write',lambda *_:self._refresh())
        self.welcome()

    def _style(self):
        style=ttk.Style(self)
        try:style.theme_use('clam')
        except tk.TclError:pass
        style.configure('P.Horizontal.TProgressbar',background=BLUE_READY,troughcolor='#E8E5DB',borderwidth=0)
        style.configure('TCombobox',padding=(7,7),foreground=NAVY,fieldbackground=WHITE,background=WHITE)

    def label(self,parent,text,size=11,bold=False,color=NAVY,wrap=0):
        return tk.Label(parent,text=text,font=('DejaVu Sans',size,'bold' if bold else 'normal'),
                        bg=parent['bg'],fg=color,anchor='w',justify='left',wraplength=wrap)

    def button(self,parent,text,command,ready=False,fill=None):
        bg=fill or (BLUE_READY if ready else BLUE_LIGHT)
        fg=WHITE if ready or bg in (ORANGE, GREEN, BLUE_READY, NAVY, PINK) else NAVY
        return tk.Button(parent,text=text,command=command,font=('DejaVu Sans',11,'bold'),
                         bg=bg,fg=fg,activebackground=BLUE_ACTIVE if ready else bg,
                         activeforeground=fg,cursor='hand2',bd=0,padx=22,pady=12,relief='flat')

    def _shell(self):
        h=tk.Frame(self,bg=YELLOW,height=100)
        h.pack(fill='x');h.pack_propagate(False)
        self.label(h,f'PsicoLab {VERSION}',24,True).pack(anchor='w',padx=30,pady=(14,0))
        self.label(h,'¿Puede un algoritmo conocerte? · Actividad exploratoria',10).pack(anchor='w',padx=31,pady=(0,8))
        d=tk.Frame(h,bg=YELLOW);d.pack(anchor='e',padx=32)
        for c in (PINK,ORANGE,BLUE_READY,GREEN):
            a=tk.Canvas(d,width=13,height=13,bg=YELLOW,highlightthickness=0)
            a.pack(side='left',padx=4);a.create_oval(1,1,12,12,fill=c,outline='')
        self.body=tk.Frame(self,bg=BG);self.body.pack(fill='both',expand=True)

    def clear(self):
        for child in self.body.winfo_children():child.destroy()
        self.canvas=None

    def scroller(self,parent,bg=WHITE):
        wrap=tk.Frame(parent,bg=bg)
        canvas=tk.Canvas(wrap,bg=bg,highlightthickness=0)
        scroll=ttk.Scrollbar(wrap,orient='vertical',command=canvas.yview)
        canvas.configure(yscrollcommand=scroll.set)
        scroll.pack(side='right',fill='y');canvas.pack(side='left',fill='both',expand=True)
        inside=tk.Frame(canvas,bg=bg)
        wid=canvas.create_window((0,0),window=inside,anchor='nw')
        inside.bind('<Configure>',lambda e:canvas.configure(scrollregion=canvas.bbox('all')))
        canvas.bind('<Configure>',lambda e:canvas.itemconfig(wid,width=e.width))
        self.canvas=canvas
        return wrap,inside

    def wheel(self,event):
        if self.canvas is None or not self.canvas.winfo_exists():return
        if getattr(event,'num',None)==4:dy=-1
        elif getattr(event,'num',None)==5:dy=1
        else:dy=-1 if getattr(event,'delta',0)>0 else 1
        self.canvas.yview_scroll(3*dy,'units')

    def _enable_scroll(self):
        self.bind_all('<MouseWheel>',self.wheel)
        self.bind_all('<Button-4>',self.wheel)
        self.bind_all('<Button-5>',self.wheel)

    def welcome(self):
        self.mode='welcome';self.clear()
        panel=tk.Frame(self.body,bg=WHITE,highlightbackground=LINE,highlightthickness=1)
        panel.pack(fill='both',expand=True,padx=50,pady=35)
        decor=tk.Frame(panel,bg=YELLOW,height=18);decor.pack(fill='x')
        self.label(panel,'¿Puede un algoritmo conocerte?',26,True,wrap=940).pack(anchor='center',padx=35,pady=(72,16))
        self.label(panel,'Descubre el perfil que predice una red neuronal a partir de 20 respuestas y '
                   'explora tres áreas profesionales relacionadas con tu carrera.',12,color=MUTED,wrap=880).pack(
                   anchor='center',padx=45,pady=(0,22))
        chips=tk.Frame(panel,bg=WHITE);chips.pack(pady=(5,28))
        for text,bg in [('20 reactivos',YELLOW),('16 perfiles',PINK),('3 opciones laborales',BLUE_READY)]:
            tk.Label(chips,text=text,bg=bg,fg=WHITE if bg!=YELLOW else NAVY,
                     font=('DejaVu Sans',10,'bold'),padx=13,pady=8).pack(side='left',padx=9)
        self.label(panel,'Actividad de divulgación; no constituye diagnóstico ni orientación laboral validada.',
                   10,color=MUTED,wrap=880).pack(anchor='center',padx=30,pady=(0,25))
        self.button(panel,'Comenzar →',self.consent_screen,ready=True).pack(pady=(0,35))

    def consent_screen(self):
        self.mode='consent';self.clear()
        out=tk.Frame(self.body,bg=BG);out.pack(fill='both',expand=True,padx=26,pady=18)
        self.label(out,'Consentimiento informado',21,True).pack(anchor='w',pady=(0,13))
        panel=tk.Frame(out,bg=WHITE,highlightbackground=LINE,highlightthickness=1)
        panel.pack(fill='both',expand=True)
        footer=tk.Frame(panel,bg=WHITE);footer.pack(side='bottom',fill='x',padx=22,pady=15)
        self.button(footer,'No acepto',self.deny_consent,fill=ORANGE).pack(side='left')
        self.button(footer,'Sí, acepto y autorizo',self.accept_consent,ready=True).pack(side='right')
        sc,inside=self.scroller(panel);sc.pack(fill='both',expand=True,padx=15,pady=10)
        self.label(inside,CONSENT_TITLE,17,True,wrap=950).pack(anchor='w',padx=14,pady=(13,17))
        self.label(inside,CONSENT_TEXT,11,wrap=890).pack(anchor='w',padx=14,pady=(0,20))
        self._enable_scroll()

    def deny_consent(self):
        self.consent=False;self.mode='declined';self.clear()
        panel=tk.Frame(self.body,bg=WHITE,highlightbackground=LINE,highlightthickness=1)
        panel.pack(fill='both',expand=True,padx=40,pady=35)
        self.label(panel,'No se autorizó la participación',22,True).pack(anchor='w',padx=30,pady=(40,12))
        self.label(panel,'El cuestionario no se abrirá ni se guardarán respuestas. Puedes volver a leer '
                   'el consentimiento o cerrar la aplicación.',11,color=MUTED,wrap=940).pack(anchor='w',padx=30,pady=(0,22))
        actions=tk.Frame(panel,bg=WHITE);actions.pack(anchor='w',padx=30)
        self.button(actions,'Revisar consentimiento',self.consent_screen).pack(side='left',padx=(0,10))
        self.button(actions,'Salir',self.destroy,fill=NAVY).pack(side='left')

    def accept_consent(self):
        self.consent=True
        self.demographics()

    def demographics(self):
        if not self.consent:
            self.consent_screen();return
        self.mode='demographics';self.clear()
        panel=tk.Frame(self.body,bg=WHITE,highlightbackground=LINE,highlightthickness=1)
        panel.pack(fill='both',expand=True,padx=37,pady=30)
        tk.Frame(panel,bg=PINK,height=13).pack(fill='x')
        self.label(panel,'Datos generales',22,True).pack(anchor='w',padx=26,pady=(24,7))
        self.label(panel,'Selecciona los tres campos obligatorios antes de iniciar el cuestionario.',
                   10,color=MUTED).pack(anchor='w',padx=26,pady=(0,20))
        fields=tk.Frame(panel,bg=WHITE);fields.pack(fill='x',padx=26)
        row=[('Edad (17 a 65 años)',self.age,[str(n) for n in range(17,66)]),
             ('Sexo',self.sex,['Masculino','Femenino']),('Licenciatura o carrera',self.career,careers())]
        self.demographics_boxes=[]
        for label,var,options in row:
            self.label(fields,label+' *',11,True).pack(anchor='w',pady=(13,6))
            select=ttk.Combobox(fields,textvariable=var,values=options,state='readonly',width=42)
            select.pack(anchor='w',ipady=5)
            self.demographics_boxes.append(select)
        self.demo_warning=self.label(panel,'',10,color=WARNING)
        self.demo_warning.pack(anchor='w',padx=26,pady=(20,0))
        controls=tk.Frame(panel,bg=WHITE);controls.pack(fill='x',padx=26,pady=(15,25))
        self.button(controls,'← Consentimiento',self.consent_screen).pack(side='left')
        self.button(controls,'Ir al cuestionario →',self._start_questionnaire,ready=True).pack(side='right')

    def _valid_demographics(self):
        return (self.age.get() in tuple(str(a) for a in range(17,66))
                and self.sex.get() in ('Masculino','Femenino')
                and self.career.get() in careers())

    def _start_questionnaire(self):
        if not self._valid_demographics():
            self.demo_warning.configure(text='Completa edad, sexo y licenciatura o carrera antes de continuar.')
            return
        self.questionnaire()

    def questionnaire(self):
        if not self.consent:
            self.consent_screen();return
        if not self._valid_demographics():
            self.demographics();return
        self.mode='questionnaire';self.clear()
        out=tk.Frame(self.body,bg=BG);out.pack(fill='both',expand=True,padx=25,pady=13)
        top=tk.Frame(out,bg=BG);top.pack(fill='x',pady=(0,10))
        self.label(top,'Cuestionario de preferencias',20,True).pack(anchor='w',pady=(0,5))
        self.label(top,f'{self.age.get()} años · {self.sex.get()} · {self.career.get()}  |  '
                   'Todas las preguntas son obligatorias.',10,color=MUTED).pack(anchor='w')
        box=tk.Frame(out,bg=WHITE,highlightbackground=LINE,highlightthickness=1)
        box.pack(fill='both',expand=True)
        # Pie fijo: el botón para ver resultados se mantiene visible al recorrer las 20 preguntas.
        foot=tk.Frame(box,bg=WHITE);foot.pack(side='bottom',fill='x',padx=20,pady=(6,13))
        self.progress=ttk.Progressbar(foot,maximum=20,style='P.Horizontal.TProgressbar')
        self.progress.pack(fill='x',pady=(0,7))
        self.progress_label=self.label(foot,'',9,color=MUTED);self.progress_label.pack(anchor='e')
        self.warning=self.label(foot,'',9,color=WARNING);self.warning.pack(anchor='w',fill='x')
        actions=tk.Frame(foot,bg=WHITE);actions.pack(fill='x',pady=(7,0))
        self.button(actions,'← Datos generales',self.demographics).pack(side='left')
        self.next=self.button(actions,'Ver mi resultado',self.result)
        self.next.pack(side='right')
        sc,inside=self.scroller(box);sc.pack(fill='both',expand=True,padx=(15,10),pady=7)
        self.questions_canvas=self.canvas
        for i,q in enumerate(self.qs):
            if i%5==0:
                title=['ORIENTACIÓN SOCIAL','PROCESAMIENTO DE INFORMACIÓN',
                       'CRITERIOS DE DECISIÓN','ORGANIZACIÓN PERSONAL'][i//5]
                col=[BLUE_READY,PINK,ORANGE,GREEN][i//5]
                self.label(inside,f'DIMENSIÓN {i//5+1} · {title}',11,True,color=col).pack(
                    anchor='w',padx=16,pady=(19,10))
            item=tk.Frame(inside,bg=WHITE)
            item.pack(fill='x',padx=15,pady=(5,5))
            self.label(item,f"{i+1:02d}. {q['question']} *",11,True,wrap=920).pack(anchor='w',pady=(0,6))
            for val in ('A','B'):
                tk.Radiobutton(item,text=f"{val}) {q[val]}",variable=self.answers[i],value=val,
                               font=('DejaVu Sans',10),fg=NAVY,bg=WHITE,activebackground=WHITE,
                               selectcolor=BLUE_LIGHT,justify='left',anchor='w',wraplength=880,
                               padx=10,pady=5).pack(anchor='w',fill='x')
            tk.Frame(inside,bg=LINE,height=1).pack(fill='x',padx=16,pady=(5,10))
        self._refresh()
        self._enable_scroll()
        self.after_idle(lambda:self.questions_canvas.yview_moveto(0))

    def _refresh(self):
        if self.mode!='questionnaire' or not hasattr(self,'next') or not self.next.winfo_exists():return
        n=sum(v.get() in ('A','B') for v in self.answers)
        self.progress['value']=n
        self.progress_label['text']=f'{n} de 20 preguntas respondidas'
        ready=n==20
        self.next.configure(bg=BLUE_READY if ready else BLUE_LIGHT,
                            fg=WHITE if ready else NAVY,
                            activebackground=BLUE_ACTIVE if ready else BLUE_LIGHT,
                            activeforeground=WHITE if ready else NAVY)
        self.warning['text']=''

    def result(self, save_record=True):
        if not self.consent:
            self.consent_screen();return
        if not self._valid_demographics():
            self.demographics();return
        missing=[i+1 for i,a in enumerate(self.answers) if a.get() not in ('A','B')]
        if missing:
            self.warning.configure(text='Faltan las preguntas: '+', '.join(str(n) for n in missing))
            # Lleva al primer reactivo sin responder; no genera una predicción parcial.
            first=(missing[0]-1)/20
            if self.canvas is not None:self.canvas.yview_moveto(first)
            return
        try:
            # Umbral fijo de operación; no aparece en el resultado del participante.
            # La red neuronal sigue calculando predict_proba internamente.
            r=predict_ai([x.get() for x in self.answers],threshold=0.80)
            jobs=career_areas(r.profile,self.career.get())
        except Exception as err:
            messagebox.showerror('No se pudo generar la predicción',str(err));return
        if ALLOW_REAL_STORAGE and save_record:
            from storage import save
            try:
                self.record_id=save(r.answers,self.career.get(),r.number,r.profile,
                                    self.record_id,age=int(self.age.get()),sex=self.sex.get())
                self.status_text='Registro consentido guardado localmente (datos seudonimizados).'
            except Exception as err:
                self.status_text='No se pudo guardar el registro: '+str(err)
        self.result_value=r
        self.mode='result';self.clear()
        outer,inside=self.scroller(self.body,BG)
        outer.pack(fill='both',expand=True,padx=24,pady=15)
        self.label(inside,'Tu resultado de inteligencia artificial',21,True).pack(anchor='w',pady=(0,7))
        self.label(inside,f'Clase {r.number:02d} de 16 · {r.profile} · Carrera: {self.career.get()}',
                   11,color=MUTED).pack(anchor='w',pady=(0,15))
        # ---------------------------------------------------------------
        # PRESENTACIÓN DE CONFIANZA DE LA IA: DESACTIVADA A SOLICITUD.
        # Para volver a mostrarla, descomentar las líneas siguientes:
        # confidence_percent = 100 * r.confidence
        # self.label(inside, f'Confianza de la IA: {confidence_percent:.1f} %',
        #            13, True, color=BLUE_READY).pack(anchor='w')
        # self.label(inside, f'Umbral: {r.threshold:.0%} · '
        #            f'{"alcanzado" if r.accepted else "no alcanzado"}',
        #            10, color=MUTED).pack(anchor='w')
        # ---------------------------------------------------------------
        panels=tk.Frame(inside,bg=BG);panels.pack(fill='x')
        left=tk.Frame(panels,bg=WHITE,highlightbackground=LINE,highlightthickness=1,width=400)
        left.pack(side='left',fill='y',padx=(0,14))
        tk.Frame(left,bg=YELLOW,height=12).pack(fill='x')
        img=Image.open(ROOT/'assets'/f'{r.profile}.png').convert('RGB')
        img.thumbnail((375,465),Image.Resampling.LANCZOS)
        self.image_ref=ImageTk.PhotoImage(img)
        tk.Label(left,image=self.image_ref,bg=WHITE).pack(padx=10,pady=(12,9))
        self.label(left,f'Tarjeta digital: {r.profile}',11,True,color=BLUE_READY).pack(anchor='w',padx=14,pady=(2,7))
        self.label(left,f'Identificador predicho: {r.number}',10).pack(anchor='w',padx=14,pady=(0,15))
        right=tk.Frame(panels,bg=WHITE,highlightbackground=LINE,highlightthickness=1)
        right.pack(side='left',fill='both',expand=True)
        tk.Frame(right,bg=PINK,height=12).pack(fill='x')
        self.label(right,'TRES OPCIONES DE TRABAJO PARA EXPLORAR',10,True,color=ORANGE).pack(
            anchor='w',padx=19,pady=(18,6))
        self.label(right,f'Basadas en tu carrera: {self.career.get()}',13,True).pack(anchor='w',padx=19,pady=(0,9))
        for i,entry in enumerate(jobs,1):
            bg,accent=JOB_BOX[i-1]
            cell=tk.Frame(right,bg=bg,highlightbackground=accent,highlightthickness=1)
            cell.pack(fill='x',padx=17,pady=5)
            self.label(cell,f"{i}. {entry['area']}",11,True,color=NAVY,wrap=520).pack(anchor='w',padx=11,pady=(10,4))
            self.label(cell,entry['actividades'],10,wrap=510).pack(anchor='w',padx=11,pady=(0,11))
        self.label(right,'Sugerencias ilustrativas: no demuestran aptitud o empleabilidad.',
                   9,color=MUTED,wrap=520).pack(anchor='w',padx=19,pady=(9,16))
        actions=tk.Frame(inside,bg=BG);actions.pack(fill='x',pady=(16,12))
        self.button(actions,'← Revisar respuestas',self.questionnaire).pack(side='left')
        self.button(actions,'Nuevo cuestionario',self.restart,fill=ORANGE).pack(side='right')
        if self.record_id:
            self.label(inside,self.status_text,9,color=SUCCESS).pack(anchor='w')
            self.label(inside,'Código de registro local: '+self.record_id,9,color=MUTED).pack(anchor='w',pady=(5,5))
            self.button(inside,'Eliminar registro de esta sesión',self.erase,fill=GREEN).pack(anchor='w',pady=(4,9))
        elif self.status_text:
            self.label(inside,self.status_text,9,color=WARNING).pack(anchor='w')
        self.label(inside,'Perfil calculado exclusivamente con la red neuronal MLP entrenada con datos sintéticos. '
                   'No equivale a un diagnóstico psicológico ni a una evaluación profesional validada.',
                   9,color=MUTED,wrap=950).pack(anchor='w',pady=(6,20))
        self._enable_scroll()

    def erase(self):
        if not self.record_id:return
        if not messagebox.askyesno('Eliminar registro','¿Eliminar las respuestas, edad, sexo y carrera de esta sesión?'):
            return
        from storage import remove
        try:
            remove(self.record_id)
        except Exception as err:
            messagebox.showerror('Error al eliminar',str(err));return
        self.record_id=None;self.status_text='Registro eliminado localmente.'
        self.result(save_record=False)

    def restart(self):
        for var in self.answers:var.set('')
        self.age.set('');self.sex.set('');self.career.set('')
        self.record_id=None;self.consent=False;self.status_text=''
        self.welcome()


def main():
    App().mainloop()

if __name__=='__main__':main()
