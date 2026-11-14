"""Solo PsicoLab 2.0: almacenamiento local voluntario, sin identificadores personales."""
import os,sys,json,sqlite3,uuid
from contextlib import contextmanager
from pathlib import Path
from datetime import datetime,timezone
from psicolab_core import profiles,careers

def storage_root():
    override=os.getenv('PSICOLAB_DATA_DIR')
    if override:return Path(override).expanduser().resolve()
    home=Path.home()
    if sys.platform.startswith('win'):return Path(os.getenv('LOCALAPPDATA',str(home/'AppData'/'Local')))/'PsicoLab2'
    if sys.platform=='darwin':return home/'Library'/'Application Support'/'PsicoLab2'
    return Path(os.getenv('XDG_DATA_HOME',str(home/'.local'/'share')))/'PsicoLab2'

def database_path():return storage_root()/'respuestas.sqlite3'

def _connect():
    p=database_path();p.parent.mkdir(parents=True,exist_ok=True)
    if os.name!='nt':p.parent.chmod(0o700)
    con=sqlite3.connect(p,timeout=10)
    con.row_factory=sqlite3.Row
    con.execute('CREATE TABLE IF NOT EXISTS respuestas (id TEXT PRIMARY KEY, fecha TEXT NOT NULL, carrera TEXT NOT NULL, respuestas TEXT NOT NULL, perfil_id INTEGER NOT NULL, perfil TEXT NOT NULL, origen TEXT NOT NULL CHECK(origen="real"))')
    # Migración no destructiva: preservar registros existentes de versiones anteriores.
    columns={row['name'] for row in con.execute('PRAGMA table_info(respuestas)')}
    if 'edad' not in columns:
        con.execute('ALTER TABLE respuestas ADD COLUMN edad INTEGER')
    if 'sexo' not in columns:
        con.execute('ALTER TABLE respuestas ADD COLUMN sexo TEXT')
    con.execute('CREATE TABLE IF NOT EXISTS modelos (id TEXT PRIMARY KEY, fecha TEXT NOT NULL, registros_nuevos INTEGER NOT NULL, registro_total INTEGER NOT NULL, ruta TEXT NOT NULL, estado TEXT NOT NULL, reporte TEXT NOT NULL)')
    return con

@contextmanager
def _db():
    # Confirma o revierte la transacción y SIEMPRE cierra la conexión
    # (en Windows un archivo abierto no se puede borrar ni mover).
    con=_connect()
    try:
        with con:yield con
    finally:
        con.close()

def save(answers,career,profile_id,profile,existing=None, *, age=None, sex=None):
    if (len(answers)!=20 or any(x not in ('A','B') for x in answers)
        or profiles().get(int(profile_id))!=profile or career not in careers()):
        raise ValueError('Registro inválido; perfil debe corresponder a la salida de la IA.')
    if age is not None and (type(age) is not int or not 17<=age<=65):
        raise ValueError('La edad debe estar entre 17 y 65 años.')
    if sex is not None and sex not in ('Masculino','Femenino'):
        raise ValueError('El sexo debe ser Masculino o Femenino.')
    if existing:
        existing=str(uuid.UUID(existing))
    identifier=existing or str(uuid.uuid4())
    now=datetime.now(timezone.utc).isoformat()
    with _db() as db:
        if existing and db.execute('SELECT 1 FROM respuestas WHERE id=?',(existing,)).fetchone():
            db.execute('UPDATE respuestas SET carrera=?,respuestas=?,perfil_id=?,perfil=?,edad=?,sexo=? WHERE id=?',
                       (career,json.dumps(list(answers)),profile_id,profile,age,sex,identifier))
        else:
            db.execute('INSERT INTO respuestas (id,fecha,carrera,respuestas,perfil_id,perfil,origen,edad,sexo) '
                       'VALUES (?,?,?,?,?,?,?,?,?)',
                       (identifier,now,career,json.dumps(list(answers)),profile_id,profile,'real',age,sex))
    if os.name!='nt':
        try:database_path().chmod(0o600)
        except OSError:pass
    return identifier

def remove(identifier):
    with _db() as db:db.execute('DELETE FROM respuestas WHERE id=?',(identifier,))

def records():
    with _db() as db: rows=db.execute('SELECT * FROM respuestas ORDER BY id').fetchall()
    out=[]
    for row in rows:
        x=dict(row);x['respuestas']=json.loads(x['respuestas'])
        if (len(x['respuestas'])!=20 or any(a not in ('A','B') for a in x['respuestas'])
            or profiles().get(x['perfil_id'])!=x['perfil'] or x['origen']!='real'
            or (x['edad'] is not None and not 17<=x['edad']<=65)
            or (x['sexo'] is not None and x['sexo'] not in ('Masculino','Femenino'))):
            raise ValueError('Registro inconsistente.')
        out.append(x)
    return out

def model_history():
    with _db() as db:return [dict(r) for r in db.execute('SELECT * FROM modelos ORDER BY fecha DESC').fetchall()]

def register_model(ident,n,total,path,report):
    now=datetime.now(timezone.utc).isoformat()
    with _db() as db:
        db.execute('INSERT INTO modelos VALUES (?,?,?,?,?,?,?)',(ident,now,n,total,str(path),'candidato',str(report)))

def activate_model(ident):
    with _db() as db:
        state=db.execute('SELECT estado FROM modelos WHERE id=?',(ident,)).fetchone()
        if not state or state['estado']!='candidato':raise ValueError('Solo se permiten modelos candidatos.')
        db.execute('UPDATE modelos SET estado="archivado" WHERE estado="activo"')
        db.execute('UPDATE modelos SET estado="activo" WHERE id=?',(ident,))
