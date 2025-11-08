# export_schema_to_csv.py
import os
import psycopg2
from psycopg2 import sql
import pandas as pd
import subprocess

# === config ===
conninfo = {
    "host": "/var/run/postgresql",
    "port": 5432,
    "dbname": "luiz", # roda \conninfo no psql pra descobrir o q botar aqui
    "user": "luiz",
    "password": None
}
schema = "dw_fir"   # change if needed
outdir = "./data"     # where CSVs will be written
# ==============

os.makedirs(outdir, exist_ok=True)

conn = psycopg2.connect(**conninfo)
conn.autocommit = True  # important for CREATE SCHEMA, DROP, etc.
cur = conn.cursor()

# Roda "tudo.sql"
with open("ddl.sql", "r", encoding="utf-8") as f:
    sql_script = f.read()

cur.execute(sql_script)

with open("dml.sql", "r", encoding="utf-8") as f:
    sql_script = f.read()

cur.execute(sql_script)


subprocess.run(["python3", "populate.py", "10000"]) 


with open("dw.sql", "r", encoding="utf-8") as f:
    sql_script = f.read()

cur.execute(sql_script)


df = pd.read_csv('eventos_turismo.csv')
df['date'] = pd.to_datetime(df['date'])

# Inserir dados
for index, row in df.iterrows():
    cur.execute("""
        INSERT INTO dw_fir.dim_evento (data_evento, nome_evento, cidade_evento, estado_evento, categoria_evento)
        VALUES (%s, %s, %s, %s, %s)
    """, (row['date'], row['event'], row['city'], row['state'], row['category'] if row['category'] else "Não informado"))


with open("etl.sql", "r", encoding="utf-8") as f:
    sql_script = f.read()

cur.execute(sql_script)

# get list of tables in schema
cur.execute(
    "SELECT tablename FROM pg_tables WHERE schemaname = %s ORDER BY tablename",
    (schema,)
)
tables = [r[0] for r in cur.fetchall()]

if not tables:
    print("no tables found in schema", schema)
else:
    print(f"exporting {len(tables)} tables from schema '{schema}'")

for tbl in tables:
    filename = os.path.join(outdir, f"{tbl}.csv")
    with open(filename, "w", newline="") as f:
        q = sql.SQL("COPY {}.{} TO STDOUT WITH CSV HEADER").format(
            sql.Identifier(schema),
            sql.Identifier(tbl),
        ).as_string(conn)
        cur.copy_expert(q, f)
    print("wrote", filename)

cur.close()
conn.close()

