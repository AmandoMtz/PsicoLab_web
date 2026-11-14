#!/usr/bin/env python3
"""Reentrenamiento opcional y supervisado, no disponible en pantalla pública de PsicoLab 2.0."""
from __future__ import annotations
import argparse,csv,hashlib,json,uuid,shutil,os
from datetime import datetime,timezone
from pathlib import Path
from psicolab_core import ROOT,MODEL
from storage import records,model_history,register_model,activate_model,storage_root

def need_sklearn():
    import numpy as np
    import joblib
    from sklearn.neural_network import MLPClassifier
    from sklearn.metrics import accuracy_score,f1_score
    return np,joblib,MLPClassifier,accuracy_score,f1_score

def split_real(xs):
    key=''.join(xs).encode('ascii');value=int.from_bytes(hashlib.sha256(key).digest()[:8],'big')%100
    return 'train' if value<70 else ('validation' if value<85 else 'test')

def data_synthetic():
    import pandas as pd
    df=pd.read_csv(ROOT/'datos'/'entrenamiento_12000_sinteticos.csv')
    x=df[[f'R{i:02d}' for i in range(1,21)]].to_numpy(dtype=float)
    y=df['Tipo_personalidad'].to_numpy(dtype=int)
    # Group-split by pattern, deterministic. The same pattern never crosses sets.
    idx=[''.join('B' if i else 'A' for i in row) for row in x]
    labels=[split_real(k) for k in idx]
    return {k:(x[[a==k for a in labels]],y[[a==k for a in labels]]) for k in ('train','validation','test')}

def data_real():
    np,*_=need_sklearn()
    rs=records(); groups={k:([],[]) for k in ('train','validation','test')}
    for r in rs:
        x=[0 if v=='A' else 1 for v in r['respuestas']]
        name=split_real(r['respuestas'])
        groups[name][0].append(x);groups[name][1].append(r['perfil_id'])
    return {k:(np.asarray(x,dtype=float).reshape(-1,20),np.asarray(y,dtype=int)) for k,(x,y) in groups.items()}

def assess(model,x,y):
    *_,acc,f1=need_sklearn()
    if len(y)==0:return {'n':0,'accuracy':None,'f1_macro':None}
    p=model.predict(x)
    return {'n':len(y),'accuracy':float(acc(y,p)),'f1_macro':float(f1(y,p,average='macro',zero_division=0))}

def saved_model():
    _,joblib,*_=need_sklearn()
    active=storage_root()/'modelos'/'activo.joblib'
    return joblib.load(active if active.exists() else MODEL)['model']

def command_status(_args):
    rows=records();h=model_history()
    last_date=h[0]['fecha'] if h else None
    recent=sum(1 for r in rows if last_date is None or r['fecha']>last_date)
    print(json.dumps({'registros_reales_consentidos':len(rows),'nuevos_desde_entrenamiento':recent,
       'modelos':[{k:r[k] for k in ('id','estado','fecha','registro_total')} for r in h],
       'directorio_local_privado':str(storage_root())},ensure_ascii=False,indent=2))

def command_train(args):
    np,joblib,MLPClassifier,*_=need_sklearn()
    real=records();h=model_history();last_date=h[0]['fecha'] if h else None
    fresh=sum(1 for r in real if last_date is None or r['fecha']>last_date)
    if fresh<args.min_nuevos:raise ValueError(f'Se requieren al menos {args.min_nuevos} ingresos reales nuevos; disponibles {fresh}.')
    rs=data_real();ss=data_synthetic()
    if len(rs['train'][1])<30 or len(rs['validation'][1])<10:
        raise ValueError('No hay suficientes reales separados (mínimo 30 train, 10 validación).')
    X=np.concatenate((ss['train'][0],rs['train'][0]));Y=np.concatenate((ss['train'][1],rs['train'][1]))
    model=MLPClassifier(hidden_layer_sizes=(64,32),random_state=args.seed,max_iter=350,
                        alpha=.001,learning_rate_init=.001,batch_size=64,early_stopping=True,n_iter_no_change=30)
    model.fit(X,Y)
    baseline=saved_model()
    metrics={name:{'candidato':assess(model,*split['validation']), 'activo':assess(baseline,*split['validation'])}
             for name,split in [('sinteticos',ss),('reales',rs)]}
    eligible=all(m['candidato']['accuracy'] is not None and m['candidato']['accuracy']>=.85 and
                 m['candidato']['accuracy']+.02>=m['activo']['accuracy'] for m in metrics.values())
    ident=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+uuid.uuid4().hex[:6]
    out=storage_root()/'modelos'/'candidatos';out.mkdir(parents=True,exist_ok=True)
    path=out/(ident+'.joblib');reportpath=out/(ident+'.json')
    payload={'model':model,'features':[f'R{i:02d}' for i in range(1,21)],'classes':list(range(1,17)),
             'version':'MLP-12000-real-candidate-'+ident}
    report={'id':ident,'real_total':len(real),'new_real':fresh,'training':{'sinteticos':len(ss['train'][1]),'reales':len(rs['train'][1])},
            'validation':metrics,'eligible':eligible,'test':'reservado para activación',
            'warning':'Las etiquetas de participantes son PSEUDOETIQUETAS generadas por la propia red; entrenar con ellas no demuestra aprender personalidad real ni mejora psicométrica.'}
    joblib.dump(payload,path)
    reportpath.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    register_model(ident,fresh,len(real),path,reportpath)
    print(json.dumps(report,ensure_ascii=False,indent=2));print('No se activó automáticamente. REVISAR: etiquetas reales = predicción de la IA, NO verdad externa.')

def command_activate(args):
    if not args.confirmar: raise ValueError('Falta --confirmar.')
    np,joblib,*_=need_sklearn()
    row=next((r for r in model_history() if r['id']==args.id),None)
    if not row or row['estado']!='candidato':raise ValueError('Identificador no es candidato.')
    path=Path(row['ruta']).resolve();allowed=(storage_root()/'modelos'/'candidatos').resolve()
    if path.parent!=allowed or not path.is_file():raise ValueError('Archivo inválido.')
    reportpath=Path(row['reporte']).resolve()
    if reportpath.parent!=allowed:raise ValueError('Reporte fuera del directorio autorizado.')
    report=json.loads(reportpath.read_text(encoding='utf-8'))
    if not report['eligible']:raise ValueError('El candidato no cumple criterios de validación.')
    payload=joblib.load(path)
    if payload.get('features')!=[f'R{i:02d}' for i in range(1,21)] or list(payload.get('classes',[]))!=list(range(1,17)):
        raise ValueError('Modelo con clases o variables incorrectas.')
    baseline=saved_model();ss=data_synthetic();rs=data_real()
    if len(rs['validation'][1])<10:raise ValueError('Ya no existe una validación real suficiente.')
    for name,items in [('sinteticos',ss),('reales',rs)]:
        prev=assess(baseline,*items['validation']);curr=assess(payload['model'],*items['validation'])
        if curr['accuracy'] is None or curr['accuracy']+.02<prev['accuracy'] or curr['accuracy']<.85:
            raise ValueError('El modelo no supera la revalidación de '+name)
    report['test']={name:{'candidato':assess(payload['model'],*items['test']), 'anterior':assess(baseline,*items['test'])}
                    for name,items in [('sinteticos',ss),('reales',rs)]}
    target=storage_root()/'modelos'/'activo.joblib';temp=target.with_suffix('.tmp')
    shutil.copy2(path,temp);os.replace(temp,target)
    activate_model(args.id);reportpath.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print('Modelo activado por investigador:',args.id)
    print(json.dumps(report['test'],ensure_ascii=False,indent=2))

def command_export(args):
    if Path(args.salida).exists():raise FileExistsError('El archivo destino ya existe.')
    rows=records()
    with open(args.salida,'w',encoding='utf-8-sig',newline='') as out:
        field=['id','fecha','origen','edad','sexo','carrera','perfil_id','perfil']+[f'R{i:02d}' for i in range(1,21)]
        wr=csv.DictWriter(out,fieldnames=field);wr.writeheader()
        for r in rows:
            data={key:r[key] for key in field[:8]}
            data.update({f'R{i:02d}':0 if a=='A' else 1 for i,a in enumerate(r['respuestas'],1)})
            wr.writerow(data)
    print('Se exportaron',len(rows),'registros consentidos. Proteger el archivo de salida.')

def main():
    p=argparse.ArgumentParser();sub=p.add_subparsers(dest='action',required=True)
    sub.add_parser('estado');tr=sub.add_parser('entrenar');tr.add_argument('--min-nuevos',type=int,default=100);tr.add_argument('--seed',type=int,default=42)
    ac=sub.add_parser('activar');ac.add_argument('--id',required=True);ac.add_argument('--confirmar',action='store_true')
    exp=sub.add_parser('exportar');exp.add_argument('--salida',required=True)
    args=p.parse_args();{'estado':command_status,'entrenar':command_train,'activar':command_activate,'exportar':command_export}[args.action](args)
if __name__=='__main__':main()
