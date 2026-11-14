import os,sys,tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from storage import save,remove,records,database_path
from psicolab_core import questions,predict_ai

def run():
    with tempfile.TemporaryDirectory() as tmp:
        os.environ['PSICOLAB_DATA_DIR']=tmp
        code='INTJ'
        ans=['A' if q['pole_A']==code[(q['id']-1)//5] else 'B' for q in questions()]
        sc=predict_ai(ans)
        assert not database_path().exists()
        record=save(ans,'Derecho',sc.number,sc.profile)
        assert len(records())==1 and records()[0]['perfil_id']==11
        newer=save(ans,'Psicología',sc.number,sc.profile,record)
        assert newer==record and len(records())==1
        remove(record)
        assert len(records())==0
    print('Storage OK')
if __name__=='__main__':run()
