"""Pruebas de predicción neuronal pura, 16 tarjetas aportadas y cinco folds."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from psicolab_core import questions,profiles,predict_ai,career_areas,careers,validation_report,validate_12000

def test_dataset_and_5folds():
    audit=validate_12000()
    assert audit['registros']==12000 and audit['patrones_unicos']==11057
    report=validation_report()
    assert len(report['folds'])==5
    assert sum(f['test_size'] for f in report['folds'])==12000
    assert all(f['accuracy']>=0.98 for f in report['folds'])
    assert len(report['threshold_evaluation'])>=5
    assert all(t['selected']<=12000 for t in report['threshold_evaluation'])

def test_all_16_classes_reachable_and_card_mapping():
    assert len(questions())==20
    for idx,code in profiles().items():
        answers=['A' if q['pole_A']==code[(q['id']-1)//5] else 'B' for q in questions()]
        result=predict_ai(answers,threshold=.80)
        assert result.number==idx and result.profile==code
        assert 0<=result.confidence<=1
        assert len(result.alternatives)==3
        path=Path(__file__).resolve().parents[1]/'assets'/f'{code}.png'
        assert path.is_file() and path.stat().st_size>10000

def test_threshold_changes_status_not_class():
    answers=['A']*20
    low=predict_ai(answers,threshold=.60)
    high=predict_ai(answers,threshold=.95)
    assert low.profile==high.profile and low.number==high.number
    assert low.accepted==(low.confidence>=.60)
    assert high.accepted==(high.confidence>=.95)

def test_career_suggestions():
    assert careers()==['Derecho','Comunicación','Turismo','Psicología','Inglés','Economía y Finanzas']
    for profile in profiles().values():
        for career in careers():
            jobs=career_areas(profile,career)
            assert len(jobs)==3
            assert len({j['area'] for j in jobs})==3
