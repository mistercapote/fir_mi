DROP schema IF EXISTS fir CASCADE;
CREATE schema fir;

set search_path=fir;

CREATE TABLE Veiculo
(
  IDVeiculo INT NOT NULL,
  TipoVeiculo VARCHAR NOT NULL,
  PlacaVeiculo CHAR(7) NOT NULL,
  DescricaoVeic VARCHAR,
  PRIMARY KEY (IDVeiculo),
  UNIQUE (PlacaVeiculo)
);

CREATE TABLE Funcionario
(
  IDFunc INT NOT NULL,
  NomeFunc VARCHAR(100) NOT NULL,
  CPFFunc CHAR(11) NOT NULL,
  SalarioFunc NUMERIC(20, 2) NOT NULL,
  PRIMARY KEY (IDFunc),
  UNIQUE (CPFFunc)
);

CREATE TABLE Motorista
(
  IDFunc INT NOT NULL,
  PRIMARY KEY (IDFunc),
  FOREIGN KEY (IDFunc) REFERENCES Funcionario(IDFunc)
);

CREATE TABLE Administrativo
(
  IDFunc INT NOT NULL,
  PRIMARY KEY (IDFunc),
  FOREIGN KEY (IDFunc) REFERENCES Funcionario(IDFunc)
);

CREATE TABLE Manutencao
(
  IDManut INT NOT NULL,
  DescricaoManut VARCHAR NOT NULL,
  DataManut DATE NOT NULL,
  DespesaManut FLOAT NOT NULL,
  IDVeiculo INT NOT NULL,
  PRIMARY KEY (IDManut),
  FOREIGN KEY (IDVeiculo) REFERENCES Veiculo(IDVeiculo)
);

CREATE TABLE Passageiro
(
  IDPassageiro INT NOT NULL,
  NomePassageiro VARCHAR(100) NOT NULL,
  CPFPassageiro CHAR(11) NOT NULL,
  DataNascPassageiro DATE NOT NULL,
  PRIMARY KEY (IDPassageiro),
  UNIQUE (CPFPassageiro)
);

CREATE TABLE Endereco
(
  IDEndereco INT NOT NULL,
  CEP CHAR(8) NOT NULL,
  Municipio VARCHAR NOT NULL,
  Numero INT NOT NULL,
  UF VARCHAR(2) NOT NULL,
  Endereco VARCHAR NOT NULL,
  PontoReferencia VARCHAR NOT NULL,
  PRIMARY KEY (IDEndereco)
);

CREATE TABLE Pagamento
(
  IDPagto INT NOT NULL,
  ValorPagto FLOAT NOT NULL,
  ValorImposto FLOAT NOT NULL,
  DtPagto DATE NOT NULL,
  IDFunc INT NOT NULL,
  PRIMARY KEY (IDPagto),
  FOREIGN KEY (IDFunc) REFERENCES Funcionario(IDFunc)
);

CREATE TABLE Rota
(
  IDRota INT NOT NULL,
  DtHrInicio TIMESTAMP NOT NULL,
  DtHrFim TIMESTAMP NOT NULL,
  ValorDaPassagem NUMERIC(20, 2) NOT NULL,
  IDFunc INT NOT NULL,
  IDVeiculo INT NOT NULL,
  IDEnderecoDestino INT NOT NULL,
  IDEnderecoOrigem INT NOT NULL,
  PRIMARY KEY (IDRota),
  FOREIGN KEY (IDFunc) REFERENCES Motorista(IDFunc),
  FOREIGN KEY (IDVeiculo) REFERENCES Veiculo(IDVeiculo),
  FOREIGN KEY (IDEnderecoDestino) REFERENCES Endereco(IDEndereco),
  FOREIGN KEY (IDEnderecoOrigem) REFERENCES Endereco(IDEndereco)
);

CREATE TABLE PassRota
(
  DtHrPagtoPassagem TIMESTAMP NOT NULL,
  IDPassageiro INT NOT NULL,
  IDRota INT NOT NULL,

  PRIMARY KEY (IDPassageiro, IDRota),
  FOREIGN KEY (IDPassageiro) REFERENCES Passageiro(IDPassageiro),
  FOREIGN KEY (IDRota) REFERENCES Rota(IDRota)
);

CREATE TABLE EnderPass
(
  IDEndereco INT NOT NULL,
  IDPassageiro INT NOT NULL,
  PRIMARY KEY (IDEndereco, IDPassageiro),
  FOREIGN KEY (IDEndereco) REFERENCES Endereco(IDEndereco),
  FOREIGN KEY (IDPassageiro) REFERENCES Passageiro(IDPassageiro)
);

CREATE TABLE SugestaoRota
(
  OrigemOuDestino VARCHAR NOT NULL,
  DtHrSugestao TIMESTAMP NOT NULL,
  IDPassageiro INT NOT NULL,
  IDEndereco INT NOT NULL,
  PRIMARY KEY (IDPassageiro, IDEndereco),
  FOREIGN KEY (IDPassageiro) REFERENCES Passageiro(IDPassageiro),
  FOREIGN KEY (IDEndereco) REFERENCES Endereco(IDEndereco)
);
