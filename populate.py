import sys
import random
import datetime
from faker import Faker
import psycopg2
from psycopg2 import sql
import pandas as pd

turism_events = pd.read_csv('eventos_turismo.csv')
turism_events['date'] = pd.to_datetime(turism_events['date'])

event_routes_ids = []

fake = Faker("pt_BR")

# --- CONFIG: EDIT THIS ---
conninfo = {
    "host": "/var/run/postgresql",
    "port": 5432,
    "dbname": "luiz", # roda \conninfo no psql pra descobrir o q botar aqui
    "user": "luiz"
}
schema = "fir"
# -------------------------

conn = psycopg2.connect(**conninfo)
conn.autocommit = True
cur = conn.cursor()

def max_plus_one(table, col):
    cur.execute(sql.SQL("SELECT COALESCE(MAX({}),0) FROM {}.{}")
        .format(sql.Identifier(col),
                sql.Identifier(schema),
                sql.Identifier(table)))
    return cur.fetchone()[0] + 1

def pick_existing(table, col):
    cur.execute(sql.SQL("SELECT {} FROM {}.{} ORDER BY random() LIMIT 1")
        .format(sql.Identifier(col),
                sql.Identifier(schema),
                sql.Identifier(table)))
    r = cur.fetchone()
    return None if r is None else r[0]

# ---- EVENTS ----

def create_veiculo():
    idv = max_plus_one("veiculo", "idveiculo")
    tipo = random.choice(["Onibus", "Van", "Micro-ônibus"])
    placa = fake.unique.license_plate().replace("-", "")[:7]
    desc = fake.sentence(nb_words=5)
    cur.execute(sql.SQL("""
        INSERT INTO {}.Veiculo (IDVeiculo, TipoVeiculo, PlacaVeiculo, DescricaoVeic)
        VALUES (%s, %s, %s, %s)
    """).format(sql.Identifier(schema)), (idv, tipo, placa, desc))

def registrar_manutencao():
    idv = pick_existing("veiculo", "idveiculo")
    if idv is None:
        return
    idm = max_plus_one("manutencao", "idmanut")
    desc = fake.sentence(nb_words=6)
    data = fake.date_this_year()
    despesa = round(random.uniform(100, 5000), 2)
    cur.execute(sql.SQL("""
        INSERT INTO {}.Manutencao (IDManut, DescricaoManut, DataManut, DespesaManut, IDVeiculo)
        VALUES (%s, %s, %s, %s, %s)
    """).format(sql.Identifier(schema)), (idm, desc, data, despesa, idv))

def cadastrar_passageiro():
    idp = max_plus_one("passageiro", "idpassageiro")
    nome = fake.name()
    cpf = fake.cpf().replace(".", "").replace("-", "")
    nasc = fake.date_of_birth(minimum_age=10, maximum_age=90)
    cur.execute(sql.SQL("""
        INSERT INTO {}.Passageiro (IDPassageiro, NomePassageiro, CPFPassageiro, DataNascPassageiro)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT DO NOTHING
    """).format(sql.Identifier(schema)), (idp, nome, cpf, nasc))

def criar_rota():
    idr = max_plus_one("rota", "idrota")
    idf = pick_existing("motorista", "idfunc")
    idv = pick_existing("veiculo", "idveiculo")
    e_origem = pick_existing("endereco", "idendereco")
    e_dest = pick_existing("endereco", "idendereco")

    if None in (idf, idv, e_origem, e_dest):
        return

    start = fake.date_time_this_year()
    end = start + datetime.timedelta(minutes=random.randint(10, 240))
    val = round(random.uniform(3, 20), 2)

    cur.execute(sql.SQL("""
        INSERT INTO {}.rota
            (idrota, dthrinicio, dthrfim, valordapassagem, idfunc, idveiculo, idenderecoorigem, idenderecodestino)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT DO NOTHING;
    """).format(sql.Identifier(schema)),
    (idr, start, end, val, idf, idv, e_origem, e_dest))
    
def passageiro_compra_passagem():
    idp = pick_existing("passageiro", "idpassageiro")
    idr = pick_existing("rota", "idrota")
    if idp is None or idr is None:
        return

    t = fake.date_time_this_month()
    
    # Check the Rota table for the location 'destino' of this route
    # Then search 'events' dataframe to check if there's an event occurring at this date and location
    cur.execute(sql.SQL("""
        SELECT ed.Municipio, ed.UF, DATE(r.DtHrInicio) as data_rota
        FROM {}.Rota r
        JOIN {}.Endereco ed ON r.IDEnderecoDestino = ed.IDEndereco
        WHERE r.IDRota = %s
    """).format(sql.Identifier(schema), sql.Identifier(schema)), (idr,))
    
    rota_info = cur.fetchone()
    
    has_event = False
    if rota_info:
        municipio_destino, uf_destino, data_rota = rota_info
        
        # Check if there's an event in the events dataframe for this location and date
        event_match = turism_events[
            (turism_events['city'] == municipio_destino) & 
            (turism_events['state'] == uf_destino) & 
            (turism_events['date'] == data_rota.strftime('%Y-%m-%d'))
        ]
        
        has_event = not event_match.empty
        if (has_event):
            event_routes_ids.append(idr)

    cur.execute(sql.SQL("""
        INSERT INTO {}.PassRota (DtHrPagtoPassagem, IDPassageiro, IDRota)
        VALUES (%s, %s, %s)
        ON CONFLICT (IDPassageiro, IDRota) DO NOTHING
    """).format(sql.Identifier(schema)),
    (t, idp, idr))
    
def passageiro_compra_passagem_pra_evento():
    idp = pick_existing("passageiro", "idpassageiro")
    if len(event_routes_ids) == 0:
        return 
    idr = random.choice(event_routes_ids)
    print(idp)
    if idp is None or idr is None:
        return

    t = fake.date_time_this_month()

    cur.execute(sql.SQL("""
        INSERT INTO {}.PassRota (DtHrPagtoPassagem, IDPassageiro, IDRota)
        VALUES (%s, %s, %s)
        ON CONFLICT (IDPassageiro, IDRota) DO NOTHING
    """).format(sql.Identifier(schema)),
    (t, idp, idr))

# ---- EVENT DISTRIBUTION ----
events = [
    (5,  create_veiculo),
    (15, registrar_manutencao),
    (20, cadastrar_passageiro),
    (50, passageiro_compra_passagem),
    (10, passageiro_compra_passagem_pra_evento),
    (10, criar_rota)
]

probs = [p for p, f in events]
funcs = [f for p, f in events]

# ---- MAIN LOOP ----
if len(sys.argv) != 2:
    print("usage: python simulate.py <steps>")
    sys.exit(1)

steps = int(sys.argv[1])

for _ in range(steps):
    f = random.choices(funcs, weights=probs, k=1)[0]
    f()

cur.close()
conn.close()
print("done")
