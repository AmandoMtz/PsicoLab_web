import json, csv, time
from pathlib import Path
from collections import Counter
import numpy as np
import pandas as pd
import joblib
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score, f1_score, log_loss, confusion_matrix

ROOT=Path(__file__).resolve().parents[1]
DF=pd.read_csv(ROOT/'datos'/'entrenamiento_12000_sinteticos.csv')
FEATURES=[f'R{i:02d}' for i in range(1,21)]
X=DF[FEATURES].to_numpy(dtype=np.float32)
y=DF['Tipo_personalidad'].to_numpy(dtype=np.int64)
assert X.shape==(12000,20) and set(np.unique(y))==set(range(1,17))
patterns=[''.join(map(str,x.astype(int))) for x in X]
cv=StratifiedGroupKFold(n_splits=5,shuffle=True,random_state=20261113)
THRESHOLDS=[0.50,0.60,0.70,0.80,0.90,0.95,0.99]

def maker(seed):
 return MLPClassifier(hidden_layer_sizes=(64,32), activation='relu',solver='adam',
                      alpha=.0007,learning_rate_init=.001,batch_size=64,
                      early_stopping=True,validation_fraction=.1,n_iter_no_change=25,
                      max_iter=350,random_state=seed)

fold_results=[]
threshold_rows=[]
all_true=[]; all_predictions=[]; all_confidences=[]
start=time.time()
for fold,(train_idx,test_idx) in enumerate(cv.split(X,y,groups=patterns),1):
 assert set(patterns[i] for i in train_idx).isdisjoint(set(patterns[i] for i in test_idx))
 m=maker(42+fold);m.fit(X[train_idx],y[train_idx])
 p=m.predict_proba(X[test_idx]); classes=m.classes_; confidence=p.max(axis=1)
 predicted=classes[p.argmax(axis=1)]
 acc=accuracy_score(y[test_idx],predicted);f1=f1_score(y[test_idx],predicted,average='macro')
 fold_record=dict(fold=fold,train_size=len(train_idx),test_size=len(test_idx),
   test_unique_patterns=len(set(patterns[i] for i in test_idx)),train_unique_patterns=len(set(patterns[i] for i in train_idx)),
   accuracy=float(acc),f1_macro=float(f1),iterations=int(m.n_iter_),mean_model_score=float(confidence.mean()))
 fold_results.append(fold_record)
 for t in THRESHOLDS:
  selected=confidence>=t
  threshold_rows.append(dict(fold=fold,threshold=t,n=int(len(test_idx)),accepted=int(selected.sum()),
                            coverage=float(selected.mean()),accuracy_selected=float(accuracy_score(y[test_idx][selected],predicted[selected])) if selected.any() else None))
 all_true.extend(y[test_idx].tolist());all_predictions.extend(predicted.tolist());all_confidences.extend(confidence.tolist())
 print('FOLD',fold,fold_record,'elapsed',round(time.time()-start,1),flush=True)
all_true=np.asarray(all_true);all_predictions=np.asarray(all_predictions);all_confidences=np.asarray(all_confidences)
assert len(all_true)==12000
threshold_aggregate=[]
for t in THRESHOLDS:
 s=all_confidences>=t
 threshold_aggregate.append(dict(threshold=t,selected=int(s.sum()),n_total=len(all_true),coverage=float(s.mean()),
                                 accuracy_selected=float(accuracy_score(all_true[s],all_predictions[s])) if s.any() else None,
                                 errors_selected=int(np.sum(all_predictions[s]!=all_true[s]))))
cv_report={'protocol':'StratifiedGroupKFold(n_splits=5, shuffle=True, random_state=20261113); grupos=patrón completo de 20 respuestas; evita patrones idénticos entre entrenamiento y validación',
 'source':'12,000 respuestas sintéticas; etiquetas del instrumento, NO diagnósticos reales',
 'model':'MLPClassifier(20,64,32,16), ReLU, Adam, early stopping, 350 iteraciones máx',
 'features':FEATURES,'n_records':len(y),'n_unique_patterns':len(set(patterns)),
 'folds':fold_results,'summary':{'accuracy_mean':float(np.mean([a['accuracy'] for a in fold_results])),
 'accuracy_std':float(np.std([a['accuracy'] for a in fold_results],ddof=1)),
 'f1_macro_mean':float(np.mean([a['f1_macro'] for a in fold_results])),
 'f1_macro_std':float(np.std([a['f1_macro'] for a in fold_results],ddof=1)),
 'all_folds_accuracy':float(accuracy_score(all_true,all_predictions)),
 'all_folds_f1_macro':float(f1_score(all_true,all_predictions,average='macro'))},
 'threshold_evaluation':threshold_aggregate,
 'threshold_by_fold':threshold_rows,
 'note':'Los umbrales son sobre la puntuación softmax del modelo (no representan probabilidad psicológica calibrada). La exactitud seleccionada solo se calcula entre casos con confianza mayor/igual al umbral. No implica validez externa.'}
folder=ROOT/'experimentos'/'resultados_5folds'
folder.mkdir(exist_ok=True)
(folder/'validacion_5_folds.json').write_text(json.dumps(cv_report,indent=2,ensure_ascii=False),encoding='utf-8')
model=maker(2026)
model.fit(X,y)
assert list(model.classes_)==list(range(1,17))
payload={'model':model,'features':FEATURES,'classes':list(range(1,17)),
         'version':'MLP-12000-5folds-2026-11-13',
         'cross_validation':cv_report['summary'],
         'thresholds':THRESHOLDS,'input_coding':{'A':0,'B':1},
         'target':'Tipo_personalidad: 1..16',
         'data_source':'synthetic','n_training_records':12000}
joblib.dump(payload,folder/'MLP_12000_5Folds.joblib')
for path,df in [('metricas_por_fold.csv',pd.DataFrame(fold_results)),('umbrales_por_fold.csv',pd.DataFrame(threshold_rows)),('umbrales_agregados.csv',pd.DataFrame(threshold_aggregate))]:
 df.to_csv(folder/path,index=False,encoding='utf-8-sig')
print('CV SUMMARY',cv_report['summary'],'THRESHOLDS',threshold_aggregate, 'FINAL TRAIN ITERS',model.n_iter_,'TIME',round(time.time()-start,1),flush=True)
