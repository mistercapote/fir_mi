import requests
from bs4 import BeautifulSoup
import csv
from datetime import datetime
import locale
import time
import subprocess

locale.setlocale(locale.LC_TIME, "pt_BR.utf8")

# URL do formulário
URL = "https://www.turismo.gov.br/agenda-eventos/views/calendario.php"

# Parâmetros do formulário — data inicial
intervalos = [
    ("01/01/2015", "08/02/2018"),
    ("09/02/2018", "28/02/2019"),
    ("01/03/2019", "24/11/2019"),
    ("25/11/2019", "21/04/2022"),
    ("22/04/2022", "30/12/2023"),
    ("31/12/2023", "21/06/2024"),
    ("22/06/2024", "04/09/2025"),
    ("05/09/2025", "31/12/2030"),
]

# Faz a requisição POST simulando o clique em "Pesquisar"
session = requests.Session()

# Cria o CSV
with open("eventos_turismo.csv", "w", newline="", encoding="utf-8") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["date", "event", "city", "state", "category"])

    for data_inicio, data_fim in intervalos:
        payload = {
            "dataInicio": data_inicio,
            "dataFim": data_fim,
            "palavra": "",
            "estado": "",
            "cidade": "",
            "categoria": "",
        }
        
        # Faz a requisição POST
        response = session.post(URL, data=payload)
        response.raise_for_status()

        # Faz o parsing do HTML
        soup = BeautifulSoup(response.text, "html.parser")
        event_divs = soup.find_all("div", class_="col-xs-12 col-sm-12 col-md-6 col-lg-4 mt20 link")

        for div in event_divs:
            # Extrair a dados
            date = datetime.strptime(div.select_one("span.final").get_text(strip=True), "%d %b %y").strftime("%Y-%m-%d")
            event = div.select_one("div.evento span.nome").get_text(strip=True)
            city, state = [p.strip() for p in div.select_one("span.localizacao.mt").get_text(strip=True).split("/")]
            category = div.select_one("div.categoria").get_text(strip=True)
            # Escrever no CSV
            writer.writerow([date, event, city, state, category])
                
        print(f"Intervalo {data_inicio} - {data_fim} percorrido com sucesso, {len(event_divs)} linhas adicionadas")
        time.sleep(0.5)
        
print("'CSV criado com sucesso!")

# sort -r eventos_turismo.csv | uniq | grep -v ,, > eventos_turismo_temp.csv && mv eventos_turismo_temp.csv eventos_turismo.csv && rm -f eventos_turismo_temp.csv