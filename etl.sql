
-- ETL COM IGNORE DE DUPLICATAS
-- ETL para Dimensão Calendário (mantido igual)
INSERT INTO dw_fir.dim_calendario (data_completa, dia_semana, dia, mes, trimestre, ano)
SELECT DISTINCT 
    data_completa,
    CASE EXTRACT(DOW FROM data_completa)
        WHEN 0 THEN 'Domingo' WHEN 1 THEN 'Segunda-feira' 
        WHEN 2 THEN 'Terça-feira' WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira' WHEN 5 THEN 'Sexta-feira' 
        WHEN 6 THEN 'Sábado'
    END as dia_semana,
    EXTRACT(DAY FROM data_completa) as dia,
    EXTRACT(MONTH FROM data_completa) as mes,
    EXTRACT(QUARTER FROM data_completa) as trimestre,
    EXTRACT(YEAR FROM data_completa) as ano
FROM (
    SELECT DISTINCT DataManut as data_completa FROM fir.Manutencao
    UNION
    SELECT DISTINCT DtPagto as data_completa FROM fir.Pagamento
    UNION
    SELECT DISTINCT DATE(DtHrPagtoPassagem) as data_completa FROM fir.PassRota
    UNION
    SELECT DISTINCT DATE(DtHrInicio) as data_completa FROM fir.Rota
) datas
WHERE data_completa IS NOT NULL
ON CONFLICT (data_completa) DO NOTHING;

-- ETL para Dimensão Funcionário (mantido igual)
INSERT INTO dw_fir.dim_funcionario (id_funcionario, nome_funcionario, cpf_funcionario)
SELECT IDFunc, NomeFunc, CPFFunc
FROM fir.Funcionario
ON CONFLICT (id_funcionario) DO NOTHING;

-- ETL para Dimensão Veículo (mantido igual)
INSERT INTO dw_fir.dim_veiculo (id_veiculo, tipo_veiculo, placa_veiculo, descricao_veic)
SELECT IDVeiculo, TipoVeiculo, PlacaVeiculo, DescricaoVeic
FROM fir.Veiculo
ON CONFLICT (id_veiculo) DO NOTHING;

-- ETL para Dimensão Forma Pagamento (mantido igual)
INSERT INTO dw_fir.dim_forma_pagamento (forma_pagamento)
VALUES 
    ('Dinheiro'),
    ('Cartão Débito'),
    ('Cartão Crédito'),
    ('PIX'),
    ('App Pagamento')
ON CONFLICT (forma_pagamento) DO NOTHING;

-- ETL para Dimensão Passageiro (mantido igual)
INSERT INTO dw_fir.dim_passageiro (id_passageiro, nome_passageiro, cpf_passageiro)
SELECT IDPassageiro, NomePassageiro, CPFPassageiro
FROM fir.Passageiro
ON CONFLICT (id_passageiro) DO NOTHING;

-- ETL para Dimensão Localidade (mantido igual)

INSERT INTO dw_fir.dim_localidade (id_localidade, cep, municipio, uf, endereco)
SELECT IDEndereco, CEP, Municipio, UF, Endereco
FROM fir.Endereco
ON CONFLICT (id_localidade) DO NOTHING;

-- 2. Popular Fatos - DESPESAS
INSERT INTO dw_fir.fato_despesa (id_calendario, id_funcionario, id_veiculo, valor_despesa, tipo_despesa, descricao, hora_compra)
SELECT 
    dc.id_calendario,
    COALESCE(
        (SELECT IDFunc FROM fir.Administrativo LIMIT 1),
        (SELECT IDFunc FROM fir.Funcionario LIMIT 1)
    ) as id_funcionario,
    m.IDVeiculo,
    m.DespesaManut,
    'MANUTENCAO',
    m.DescricaoManut,
    '12:00:00'::time
FROM fir.Manutencao m
JOIN dw_fir.dim_calendario dc ON m.DataManut = dc.data_completa
WHERE m.IDVeiculo IN (SELECT id_veiculo FROM dw_fir.dim_veiculo)
ON CONFLICT (id_calendario, id_funcionario, id_veiculo, hora_compra) DO NOTHING;

INSERT INTO dw_fir.fato_despesa (id_calendario, id_funcionario, id_veiculo, valor_despesa, tipo_despesa, descricao, hora_compra)
SELECT 
    dc.id_calendario,
    p.IDFunc,
    COALESCE(
        (SELECT IDVeiculo FROM fir.Veiculo LIMIT 1),
        1
    ) as id_veiculo,
    p.ValorPagto,
    'FUNCIONARIO',
    'Pagamento funcionário',
    '12:00:00'::time
FROM fir.Pagamento p
JOIN dw_fir.dim_calendario dc ON p.DtPagto = dc.data_completa
WHERE p.IDFunc IN (SELECT id_funcionario FROM dw_fir.dim_funcionario)
ON CONFLICT (id_calendario, id_funcionario, id_veiculo, hora_compra) DO NOTHING;
-- ETL para Fato Receita - ABORDAGEM ALTERNATIVA

INSERT INTO dw_fir.fato_receita (
    id_calendario, 
    id_forma_pagamento, 
    id_passageiro, 
    id_origem, 
    id_destino, 
    valor_receita, 
    hora_compra,
    id_evento
)
SELECT 
    dc.id_calendario,
    1 as id_forma_pagamento, -- Assumindo forma de pagamento padrão (dinheiro)
    pr.IDPassageiro as id_passageiro,
    ro.IDEnderecoOrigem as id_origem,
    ro.IDEnderecoDestino as id_destino,
    ro.ValorDaPassagem as valor_receita,
    CAST(pr.DtHrPagtoPassagem AS TIME) as hora_compra,
    de.id_evento
FROM 
    fir.PassRota pr
    INNER JOIN fir.Rota ro ON pr.IDRota = ro.IDRota
    INNER JOIN dw_fir.dim_calendario dc ON DATE(pr.DtHrPagtoPassagem) = dc.data_completa
    INNER JOIN fir.Endereco ed ON ro.IDEnderecoDestino = ed.IDEndereco
    LEFT JOIN dw_fir.dim_evento de ON 
        ed.Municipio = de.cidade_evento 
        AND ed.UF = de.estado_evento
        AND DATE(ro.DtHrInicio) = de.data_evento
ON CONFLICT DO NOTHING;