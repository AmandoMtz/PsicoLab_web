import os,tempfile,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from psicolab_core import predict_ai,questions
from storage import save,remove,records,storage_root

def test():
    with tempfile.TemporaryDirectory() as d:
        os.environ['PSICOLAB_DATA_DIR']=d
        ans=['A' if q['pole_A']=='ENFP'[(q['id']-1)//5] else 'B' for q in questions()]
        r=predict_ai(ans)
        key=save(ans,'Comunicación',r.number,r.profile)
        assert r.number==2 and len(records())==1
        key2=save(ans,'Turismo',r.number,r.profile,key)
        assert key==key2 and len(records())==1 and records()[0]['carrera']=='Turismo'
        remove(key);assert len(records())==0
        assert storage_root().resolve()==Path(d).resolve()
    print('Consent storage update/delete valid')
if __name__=='__main__':test()
