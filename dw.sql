
DROP schema IF EXISTS dw_fir CASCADE;
CREATE schema dw_fir;

set search_path=dw_fir;

-- Dimensão Calendário
CREATE TABLE dim_calendario (
    id_calendario SERIAL PRIMARY KEY,
    data_completa DATE NOT NULL UNIQUE,
    dia_semana VARCHAR(20) NOT NULL,
    dia INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    ano INTEGER NOT NULL
);

-- Dimensão Funcionário
CREATE TABLE dim_funcionario (
    id_funcionario INTEGER PRIMARY KEY,
    nome_funcionario VARCHAR(100) NOT NULL,
    cpf_funcionario CHAR(11) NOT NULL
);

-- Dimensão Veículo
CREATE TABLE dim_veiculo (
    id_veiculo INTEGER PRIMARY KEY,
    tipo_veiculo VARCHAR NOT NULL,
    placa_veiculo CHAR(7) NOT NULL,
    descricao_veic VARCHAR
);

-- Dimensão Forma Pagamento
CREATE TABLE dim_forma_pagamento (
    id_forma_pagamento SERIAL PRIMARY KEY,
    forma_pagamento VARCHAR(50) NOT NULL UNIQUE
);

-- Dimensão Passageiro
CREATE TABLE dim_passageiro (
    id_passageiro INTEGER PRIMARY KEY,
    nome_passageiro VARCHAR(100) NOT NULL,
    cpf_passageiro CHAR(11) NOT NULL
);

-- Dimensão Localidade (Origem/Destino)
CREATE TABLE dim_localidade (
    id_localidade INTEGER PRIMARY KEY,
    cep CHAR(8) NOT NULL,
    municipio VARCHAR NOT NULL,
    uf VARCHAR(2) NOT NULL,
    endereco VARCHAR NOT NULL
);

CREATE TABLE dw_fir.dim_evento (
    id_evento SERIAL PRIMARY KEY,
    data_evento DATE NOT NULL,
    nome_evento VARCHAR(200) NOT NULL,
    cidade_evento VARCHAR(100) NOT NULL,
    estado_evento CHAR(2) NOT NULL,
    categoria_evento VARCHAR(100) NOT NULL
);


-- Tabela Fato Receita
CREATE TABLE fato_receita (
    id_calendario INTEGER NOT NULL,
    id_forma_pagamento INTEGER NOT NULL,
    id_passageiro INTEGER NOT NULL,
    id_origem INTEGER NOT NULL,
    id_destino INTEGER NOT NULL,
    valor_receita NUMERIC(20,2) NOT NULL,
    hora_compra TIME NOT NULL,
    id_evento INTEGER,

    FOREIGN KEY (id_calendario) REFERENCES dim_calendario(id_calendario),
    FOREIGN KEY (id_forma_pagamento) REFERENCES dim_forma_pagamento(id_forma_pagamento),
    FOREIGN KEY (id_passageiro) REFERENCES dim_passageiro(id_passageiro),
    FOREIGN KEY (id_origem) REFERENCES dim_localidade(id_localidade),
    FOREIGN KEY (id_destino) REFERENCES dim_localidade(id_localidade),
    FOREIGN KEY (id_evento) REFERENCES dim_evento(id_evento),
    PRIMARY KEY (id_calendario, id_passageiro, hora_compra)
);

-- Tabela Fato Despesa
CREATE TABLE fato_despesa (
    id_calendario INTEGER NOT NULL,
    id_funcionario INTEGER NOT NULL,
    id_veiculo INTEGER NOT NULL,
    valor_despesa NUMERIC(20,2) NOT NULL,
    tipo_despesa VARCHAR(20) NOT NULL, -- 'FUNCIONARIO' ou 'MANUTENCAO'
    descricao VARCHAR NOT NULL,
    hora_compra TIME NOT NULL,

    FOREIGN KEY (id_calendario) REFERENCES dim_calendario(id_calendario),
    FOREIGN KEY (id_funcionario) REFERENCES dim_funcionario(id_funcionario),
    FOREIGN KEY (id_veiculo) REFERENCES dim_veiculo(id_veiculo),

    PRIMARY KEY (id_calendario, id_funcionario, id_veiculo, hora_compra)
);
