-- Drop tables if they exist to allow clean re-runs (optional, for development)
DROP TABLE IF EXISTS vendas CASCADE;
DROP TABLE IF EXISTS financiamentos CASCADE;
DROP TABLE IF EXISTS avaliacoes_usados CASCADE;
DROP TABLE IF EXISTS historico_manutencao CASCADE;
DROP TABLE IF EXISTS veiculo_caracteristicas CASCADE;
DROP TABLE IF EXISTS veiculos CASCADE;
DROP TABLE IF EXISTS modelos CASCADE;
DROP TABLE IF EXISTS marcas CASCADE;
DROP TABLE IF EXISTS campanhas_promocoes CASCADE;
DROP TABLE IF EXISTS garantias CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;
DROP TABLE IF EXISTS vendedores CASCADE;
DROP TABLE IF EXISTS concessionarias CASCADE;
DROP TABLE IF EXISTS cidades CASCADE;
DROP TABLE IF EXISTS estados CASCADE;

CREATE TABLE estados (
    id_estados SERIAL PRIMARY KEY,
    estado VARCHAR(100) NOT NULL,
    sigla CHAR(2) NOT NULL UNIQUE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE cidades (
    id_cidades SERIAL PRIMARY KEY,
    cidade VARCHAR(255) NOT NULL,
    id_estados INTEGER NOT NULL REFERENCES estados(id_estados),
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE concessionarias (
    id_concessionarias SERIAL PRIMARY KEY,
    concessionaria VARCHAR(255) NOT NULL,
    id_cidades INTEGER NOT NULL REFERENCES cidades(id_cidades),
    endereco TEXT,
    telefone VARCHAR(20),
    email VARCHAR(255),
    horario_funcionamento VARCHAR(255),
    tem_oficina BOOLEAN DEFAULT TRUE,
    tem_assistencia_24h BOOLEAN DEFAULT FALSE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE marcas (
    id_marcas SERIAL PRIMARY KEY,
    marca VARCHAR(100) NOT NULL UNIQUE,
    pais_origem VARCHAR(100),
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE modelos (
    id_modelos SERIAL PRIMARY KEY,
    modelo VARCHAR(255) NOT NULL,
    id_marcas INTEGER NOT NULL REFERENCES marcas(id_marcas),
    categoria VARCHAR(50) NOT NULL CHECK (categoria IN ('Hatch', 'Sedan', 'SUV', 'Crossover', 'Minivan', 'Picape', 'Utilitarios', 'Esportivos')),
    ano_lancamento INTEGER,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE veiculos (
    id_veiculos SERIAL PRIMARY KEY,
    id_modelos INTEGER NOT NULL REFERENCES modelos(id_modelos),
    ano_modelo INTEGER NOT NULL,
    ano_fabricacao INTEGER NOT NULL,
    versao VARCHAR(255),
    cor VARCHAR(100),
    tipo_combustivel VARCHAR(50) CHECK (tipo_combustivel IN ('Gasolina', 'Etanol', 'Flex', 'Diesel', 'Hibrido', 'Eletrico', 'GNV')),
    potencia_cv INTEGER,
    consumo_urbano DECIMAL(4,1), -- km/l
    consumo_rodoviario DECIMAL(4,1), -- km/l
    preco_fipe DECIMAL(12, 2),
    preco_venda DECIMAL(12, 2) NOT NULL,
    tipo_veiculo VARCHAR(20) NOT NULL CHECK (tipo_veiculo IN ('Novo', 'Usado', 'Seminovo')),
    quilometragem INTEGER DEFAULT 0,
    numero_proprietarios INTEGER DEFAULT 1,
    status_veiculo VARCHAR(20) DEFAULT 'Disponivel' CHECK (status_veiculo IN ('Disponivel', 'Vendido', 'Reservado', 'Manutencao')),
    prazo_entrega_dias INTEGER DEFAULT 0,
    possui_manual BOOLEAN DEFAULT TRUE,
    possui_chave_reserva BOOLEAN DEFAULT TRUE,
    historico_batidas TEXT,
    origem VARCHAR(50) CHECK (origem IN ('Fabrica', 'Particular', 'Frota', 'Leilao')),
    ipva_anual DECIMAL(10, 2),
    licenciamento_anual DECIMAL(8, 2),
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE veiculo_caracteristicas (
    id_caracteristicas SERIAL PRIMARY KEY,
    id_veiculos INTEGER NOT NULL REFERENCES veiculos(id_veiculos),
    categoria VARCHAR(100) NOT NULL, -- Segurança, Conforto, Tecnologia, etc.
    item VARCHAR(255) NOT NULL,
    tipo VARCHAR(20) CHECK (tipo IN ('Serie', 'Opcional')),
    preco_adicional DECIMAL(10, 2) DEFAULT 0,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE campanhas_promocoes (
    id_campanhas SERIAL PRIMARY KEY,
    nome_campanha VARCHAR(255) NOT NULL,
    id_modelos INTEGER REFERENCES modelos(id_modelos),
    descricao TEXT,
    desconto_percentual DECIMAL(5,2),
    desconto_valor DECIMAL(10, 2),
    taxa_juros_especial DECIMAL(5,4),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    ativa BOOLEAN DEFAULT TRUE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE garantias (
    id_garantias SERIAL PRIMARY KEY,
    id_veiculos INTEGER NOT NULL REFERENCES veiculos(id_veiculos),
    tipo_garantia VARCHAR(50) CHECK (tipo_garantia IN ('Fabrica', 'Concessionaria', 'Estendida')),
    periodo_meses INTEGER NOT NULL,
    quilometragem_limite INTEGER,
    cobertura TEXT, -- O que a garantia cobre
    data_inicio DATE,
    data_fim DATE,
    ativa BOOLEAN DEFAULT TRUE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE vendedores (
    id_vendedores SERIAL PRIMARY KEY,
    id INTEGER,
    nome VARCHAR(255) NOT NULL,
    id_concessionarias INTEGER NOT NULL REFERENCES concessionarias(id_concessionarias),
    telefone VARCHAR(20),
    email VARCHAR(255),
    especialidade VARCHAR(100), -- Carros novos, usados, SUVs, etc.
    meta_mensal DECIMAL(12, 2),
    ativo BOOLEAN DEFAULT TRUE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE clientes (
    id_clientes SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    cpf VARCHAR(14) UNIQUE,
    endereco TEXT,
    telefone VARCHAR(20),
    email VARCHAR(255),
    data_nascimento DATE,
    renda_mensal DECIMAL(12, 2),
    score_credito INTEGER,
    possui_veiculo_troca BOOLEAN DEFAULT FALSE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE financiamentos (
    id_financiamentos SERIAL PRIMARY KEY,
    tipo_financiamento VARCHAR(50) CHECK (tipo_financiamento IN ('CDC', 'Leasing', 'Consorcio', 'A Vista')),
    banco_financiadora VARCHAR(255),
    taxa_juros_mes DECIMAL(6,4),
    taxa_juros_ano DECIMAL(6,4),
    numero_parcelas INTEGER,
    valor_entrada DECIMAL(12, 2),
    valor_parcela DECIMAL(12, 2),
    valor_total DECIMAL(12, 2),
    aprovado BOOLEAN DEFAULT NULL,
    data_aprovacao DATE,
    observacoes TEXT,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE avaliacoes_usados (
    id_avaliacoes SERIAL PRIMARY KEY,
    id_veiculos INTEGER REFERENCES veiculos(id_veiculos),
    marca VARCHAR(100),
    modelo VARCHAR(255),
    ano INTEGER,
    quilometragem INTEGER,
    estado_geral VARCHAR(50) CHECK (estado_geral IN ('Excelente', 'Muito Bom', 'Bom', 'Regular', 'Ruim')),
    valor_avaliado DECIMAL(12, 2),
    possui_debitos BOOLEAN DEFAULT FALSE,
    valor_debitos DECIMAL(10, 2) DEFAULT 0,
    documentacao_ok BOOLEAN DEFAULT TRUE,
    vistoria_realizada BOOLEAN DEFAULT FALSE,
    laudo_vistoria TEXT,
    aceita_como_troca BOOLEAN DEFAULT NULL,
    data_avaliacao DATE NOT NULL,
    avaliador VARCHAR(255),
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE historico_manutencao (
    id_historico SERIAL PRIMARY KEY,
    id_veiculos INTEGER NOT NULL REFERENCES veiculos(id_veiculos),
    tipo_servico VARCHAR(100) NOT NULL, -- Revisão, Reparo, Troca de peças, etc.
    descricao TEXT,
    quilometragem INTEGER,
    valor_servico DECIMAL(10, 2),
    data_servico DATE NOT NULL,
    oficina VARCHAR(255),
    proximo_servico_km INTEGER,
    data_proximo_servico DATE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE vendas (
    id_vendas SERIAL PRIMARY KEY,
    id_concessionarias INTEGER NOT NULL REFERENCES concessionarias(id_concessionarias),
    id_vendedores INTEGER NOT NULL REFERENCES vendedores(id_vendedores),
    id_clientes INTEGER NOT NULL REFERENCES clientes(id_clientes),
    id_veiculos INTEGER NOT NULL REFERENCES veiculos(id_veiculos),
    id_financiamentos INTEGER REFERENCES financiamentos(id_financiamentos),
    id_veiculo_troca INTEGER REFERENCES avaliacoes_usados(id_avaliacoes),
    valor_veiculo DECIMAL(12, 2) NOT NULL,
    valor_entrada DECIMAL(12, 2) DEFAULT 0,
    valor_troca DECIMAL(12, 2) DEFAULT 0,
    valor_financiado DECIMAL(12, 2) DEFAULT 0,
    valor_total_pago DECIMAL(12, 2) NOT NULL,
    custos_adicionais DECIMAL(10, 2) DEFAULT 0, -- Frete, pintura, emplacamento, etc.
    data_venda DATE NOT NULL,
    status_venda VARCHAR(30) DEFAULT 'Finalizada' CHECK (status_venda IN ('Negociacao', 'Aprovacao_Credito', 'Finalizada', 'Cancelada')),
    observacoes TEXT,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);


-- Table: seguranca_veiculos (Sistemas de segurança e crash tests)
CREATE TABLE seguranca_veiculos (
    id_seguranca SERIAL PRIMARY KEY,
    id_modelos INTEGER NOT NULL REFERENCES modelos(id_modelos),
    airbags_frontais BOOLEAN DEFAULT FALSE,
    airbags_laterais BOOLEAN DEFAULT FALSE,
    airbags_cortina BOOLEAN DEFAULT FALSE,
    freios_abs BOOLEAN DEFAULT FALSE,
    controle_estabilidade BOOLEAN DEFAULT FALSE,
    controle_tracao BOOLEAN DEFAULT FALSE,
    assistente_partida_rampa BOOLEAN DEFAULT FALSE,
    camera_re BOOLEAN DEFAULT FALSE,
    sensores_estacionamento BOOLEAN DEFAULT FALSE,
    alerta_ponto_cego BOOLEAN DEFAULT FALSE,
    frenagem_autonoma_emergencia BOOLEAN DEFAULT FALSE,
    nota_latin_ncap DECIMAL(3,1), -- 0.0 a 5.0
    ano_teste_ncap INTEGER,
    sistema_antifurto VARCHAR(100),
    alarme_fabrica BOOLEAN DEFAULT FALSE,
    trava_eletrica BOOLEAN DEFAULT FALSE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE indices_roubo_furto (
    id_indice SERIAL PRIMARY KEY,
    id_modelos INTEGER NOT NULL REFERENCES modelos(id_modelos),
    id_cidades INTEGER NOT NULL REFERENCES cidades(id_cidades),
    ano_referencia INTEGER NOT NULL,
    quantidade_roubos INTEGER DEFAULT 0,
    quantidade_furtos INTEGER DEFAULT 0,
    total_frota_estimada INTEGER,
    indice_roubo_por_mil DECIMAL(6,2), -- roubos por 1000 veículos
    ranking_nacional INTEGER, -- posição no ranking de mais roubados
    fonte_dados VARCHAR(255) DEFAULT 'Seguradora/Polícia Civil',
    data_atualizacao_dados DATE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE custos_manutencao_detalhados (
    id_custo_manutencao SERIAL PRIMARY KEY,
    id_modelos INTEGER NOT NULL REFERENCES modelos(id_modelos),
    tipo_custo VARCHAR(100) NOT NULL, -- 'Revisao_10k', 'Revisao_20k', 'Pastilha_Freio', etc.
    quilometragem_referencia INTEGER,
    valor_medio_peca DECIMAL(10, 2) DEFAULT 0,
    valor_medio_mao_obra DECIMAL(10, 2) DEFAULT 0,
    valor_total_medio DECIMAL(10, 2) NOT NULL,
    periodicidade_meses INTEGER,
    disponibilidade_pecas VARCHAR(50) CHECK (disponibilidade_pecas IN ('Alta', 'Media', 'Baixa', 'Rara')),
    facilidade_mao_obra VARCHAR(50) CHECK (facilidade_mao_obra IN ('Facil', 'Media', 'Dificil', 'Especializada')),
    regiao_referencia VARCHAR(100) DEFAULT 'Nacional',
    fonte_dados VARCHAR(255) DEFAULT 'Concessionárias/Oficinas',
    data_atualizacao_dados DATE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE custos_seguro_detalhados (
    id_seguro SERIAL PRIMARY KEY,
    id_modelos INTEGER NOT NULL REFERENCES modelos(id_modelos),
    id_cidades INTEGER NOT NULL REFERENCES cidades(id_cidades),
    idade_condutor_min INTEGER DEFAULT 18,
    idade_condutor_max INTEGER DEFAULT 100,
    tempo_cnh_anos INTEGER DEFAULT 0,
    genero VARCHAR(20) CHECK (genero IN ('Masculino', 'Feminino', 'Unissex')),
    valor_anual_medio DECIMAL(10, 2) NOT NULL,
    valor_anual_minimo DECIMAL(10, 2),
    valor_anual_maximo DECIMAL(10, 2),
    franquia_media DECIMAL(10, 2),
    cobertura_tipo VARCHAR(100) DEFAULT 'Básica', -- Básica, Intermediária, Completa
    seguradora_exemplo VARCHAR(255),
    ano_referencia INTEGER DEFAULT EXTRACT(YEAR FROM NOW()),
    data_cotacao DATE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE impacto_ambiental (
    id_impacto SERIAL PRIMARY KEY,
    id_modelos INTEGER NOT NULL REFERENCES modelos(id_modelos),
    emissao_co2_urbano DECIMAL(6, 2), -- g/km
    emissao_co2_rodoviario DECIMAL(6, 2), -- g/km
    classificacao_proconve VARCHAR(10), -- L6, L7, etc.
    nota_sustentabilidade DECIMAL(3,1), -- 0.0 a 10.0
    reciclabilidade_percentual DECIMAL(5,2), -- % do veículo reciclável
    uso_materiais_renovaveis BOOLEAN DEFAULT FALSE,
    motor_euro VARCHAR(10), -- Euro 5, Euro 6, etc.
    particulas_poluentes VARCHAR(100), -- NOx, PM, etc.
    ruido_externo_db DECIMAL(4,1), -- decibéis
    certificacao_ambiental VARCHAR(255), -- ISO 14001, etc.
    data_certificacao DATE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE incentivos_fiscais (
    id_incentivo SERIAL PRIMARY KEY,
    id_modelos INTEGER REFERENCES modelos(id_modelos),
    tipo_combustivel VARCHAR(50),
    id_cidades INTEGER REFERENCES cidades(id_cidades),
    tipo_incentivo VARCHAR(100) NOT NULL, -- 'IPVA_Reducao', 'Isencao_Rodizio', etc.
    descricao TEXT,
    percentual_desconto DECIMAL(5,2), -- % de desconto
    valor_desconto_fixo DECIMAL(10, 2), -- valor fixo de desconto
    vigencia_inicio DATE,
    vigencia_fim DATE,
    condicoes TEXT, -- condições para obter o benefício
    orgao_responsavel VARCHAR(255),
    lei_decreto VARCHAR(255), -- número da lei/decreto
    ativo BOOLEAN DEFAULT TRUE,
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE historico_valorizacao (
    id_valorizacao SERIAL PRIMARY KEY,
    id_modelos INTEGER NOT NULL REFERENCES modelos(id_modelos),
    ano_modelo INTEGER NOT NULL,
    mes_referencia DATE NOT NULL,
    valor_0km DECIMAL(12, 2), -- valor quando 0km
    valor_atual DECIMAL(12, 2), -- valor atual na data
    depreciacao_percentual DECIMAL(6,3), -- % de depreciação
    posicao_ranking_retencao INTEGER, -- ranking de retenção de valor
    facilidade_venda VARCHAR(50) CHECK (facilidade_venda IN ('Muito_Facil', 'Facil', 'Media', 'Dificil', 'Muito_Dificil')),
    tempo_medio_venda_dias INTEGER, -- tempo médio para vender
    liquidez_mercado VARCHAR(50) CHECK (liquidez_mercado IN ('Alta', 'Media', 'Baixa')),
    fonte_dados VARCHAR(255) DEFAULT 'FIPE/KBB',
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE recalls_problemas (
    id_recall SERIAL PRIMARY KEY,
    id_modelos INTEGER NOT NULL REFERENCES modelos(id_modelos),
    ano_modelo_inicio INTEGER,
    ano_modelo_fim INTEGER,
    numero_recall VARCHAR(50),
    tipo_problema VARCHAR(100) NOT NULL, -- 'Recall', 'Problema_Conhecido', 'Defeito_Serie'
    categoria_problema VARCHAR(100), -- 'Motor', 'Freios', 'Eletrico', etc.
    descricao_problema TEXT NOT NULL,
    gravidade VARCHAR(50) CHECK (gravidade IN ('Baixa', 'Media', 'Alta', 'Critica')),
    solucao TEXT,
    status_solucao VARCHAR(50) CHECK (status_solucao IN ('Pendente', 'Em_Andamento', 'Resolvido')),
    custo_reparo_estimado DECIMAL(10, 2),
    data_identificacao DATE,
    data_comunicado_oficial DATE,
    orgao_responsavel VARCHAR(255) DEFAULT 'DENATRAN',
    chassi_afetados INTEGER, -- quantidade de chassi afetados
    data_inclusao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cidades_id_estados ON cidades (id_estados);
CREATE INDEX idx_concessionarias_id_cidades ON concessionarias (id_cidades);
CREATE INDEX idx_modelos_id_marcas ON modelos (id_marcas);
CREATE INDEX idx_veiculos_id_modelos ON veiculos (id_modelos);
CREATE INDEX idx_veiculos_tipo ON veiculos (tipo_veiculo);
CREATE INDEX idx_veiculos_status ON veiculos (status_veiculo);
CREATE INDEX idx_veiculo_caracteristicas_id_veiculos ON veiculo_caracteristicas (id_veiculos);
CREATE INDEX idx_vendedores_id_concessionarias ON vendedores (id_concessionarias);
CREATE INDEX idx_vendas_data_venda ON vendas (data_venda);
CREATE INDEX idx_vendas_status ON vendas (status_venda);
CREATE INDEX idx_campanhas_ativa ON campanhas_promocoes (ativa);
CREATE INDEX idx_garantias_ativa ON garantias (ativa);

CREATE INDEX idx_seguranca_veiculos_modelos ON seguranca_veiculos (id_modelos);
CREATE INDEX idx_indices_roubo_furto_modelos ON indices_roubo_furto (id_modelos);
CREATE INDEX idx_indices_roubo_furto_cidades ON indices_roubo_furto (id_cidades);
CREATE INDEX idx_custos_manutencao_modelos ON custos_manutencao_detalhados (id_modelos);
CREATE INDEX idx_custos_seguro_modelos ON custos_seguro_detalhados (id_modelos);
CREATE INDEX idx_custos_seguro_cidades ON custos_seguro_detalhados (id_cidades);
CREATE INDEX idx_impacto_ambiental_modelos ON impacto_ambiental (id_modelos);
CREATE INDEX idx_incentivos_fiscais_modelos ON incentivos_fiscais (id_modelos);
CREATE INDEX idx_incentivos_fiscais_ativo ON incentivos_fiscais (ativo);
CREATE INDEX idx_historico_valorizacao_modelos ON historico_valorizacao (id_modelos);
CREATE INDEX idx_recalls_problemas_modelos ON recalls_problemas (id_modelos);
CREATE INDEX idx_recalls_problemas_gravidade ON recalls_problemas (gravidade);

-- Insert fake data

INSERT INTO estados (estado, sigla) VALUES
('São Paulo', 'SP'),
('Rio de Janeiro', 'RJ'),
('Minas Gerais', 'MG'),
('Paraná', 'PR'),
('Santa Catarina', 'SC');

INSERT INTO cidades (cidade, id_estados) VALUES
('São Paulo', (SELECT id_estados FROM estados WHERE sigla = 'SP')),
('Campinas', (SELECT id_estados FROM estados WHERE sigla = 'SP')),
('São Bernardo do Campo', (SELECT id_estados FROM estados WHERE sigla = 'SP')),
('Rio de Janeiro', (SELECT id_estados FROM estados WHERE sigla = 'RJ')),
('Niterói', (SELECT id_estados FROM estados WHERE sigla = 'RJ')),
('Belo Horizonte', (SELECT id_estados FROM estados WHERE sigla = 'MG')),
('Curitiba', (SELECT id_estados FROM estados WHERE sigla = 'PR')),
('Florianópolis', (SELECT id_estados FROM estados WHERE sigla = 'SC'));

INSERT INTO concessionarias (concessionaria, id_cidades, endereco, telefone, email, horario_funcionamento, tem_oficina, tem_assistencia_24h) VALUES
('Toyota Premium SP', (SELECT id_cidades FROM cidades WHERE cidade = 'São Paulo' LIMIT 1), 'Av. Paulista, 1000', '(11) 3000-1000', 'vendas@toyotasp.com.br', 'Seg-Sex: 8h-18h, Sab: 8h-14h', TRUE, TRUE),
('Honda Campinas', (SELECT id_cidades FROM cidades WHERE cidade = 'Campinas' LIMIT 1), 'Av. das Avenidas, 500', '(19) 3500-2000', 'vendas@hondacampinas.com.br', 'Seg-Sex: 8h-18h, Sab: 8h-16h', TRUE, FALSE),
('Volkswagen RJ', (SELECT id_cidades FROM cidades WHERE cidade = 'Rio de Janeiro' LIMIT 1), 'Av. Presidente Vargas, 2000', '(21) 2500-3000', 'vendas@vwrj.com.br', 'Seg-Sex: 8h-19h, Sab: 8h-15h', TRUE, TRUE),
('Fiat Belo Horizonte', (SELECT id_cidades FROM cidades WHERE cidade = 'Belo Horizonte' LIMIT 1), 'Av. Afonso Pena, 1500', '(31) 3200-4000', 'vendas@fiatbh.com.br', 'Seg-Sex: 8h-18h, Sab: 8h-14h', TRUE, FALSE);

INSERT INTO marcas (marca, pais_origem) VALUES
('Toyota', 'Japão'),
('Honda', 'Japão'),
('Volkswagen', 'Alemanha'),
('Fiat', 'Itália'),
('Chevrolet', 'Estados Unidos'),
('Jeep', 'Estados Unidos'),
('Hyundai', 'Coreia do Sul'),
('Nissan', 'Japão'),
('Ford', 'Estados Unidos'),
('Renault', 'França');

INSERT INTO modelos (modelo, id_marcas, categoria, ano_lancamento) VALUES
('Corolla', (SELECT id_marcas FROM marcas WHERE marca = 'Toyota'), 'Sedan', 1966),
('Civic', (SELECT id_marcas FROM marcas WHERE marca = 'Honda'), 'Sedan', 1972),
('T-Cross', (SELECT id_marcas FROM marcas WHERE marca = 'Volkswagen'), 'SUV', 2018),
('Argo', (SELECT id_marcas FROM marcas WHERE marca = 'Fiat'), 'Hatch', 2017),
('Onix', (SELECT id_marcas FROM marcas WHERE marca = 'Chevrolet'), 'Hatch', 2012),
('Renegade', (SELECT id_marcas FROM marcas WHERE marca = 'Jeep'), 'SUV', 2014),
('HB20', (SELECT id_marcas FROM marcas WHERE marca = 'Hyundai'), 'Hatch', 2012),
('Kicks', (SELECT id_marcas FROM marcas WHERE marca = 'Nissan'), 'SUV', 2016),
('EcoSport', (SELECT id_marcas FROM marcas WHERE marca = 'Ford'), 'SUV', 2003),
('Sandero', (SELECT id_marcas FROM marcas WHERE marca = 'Renault'), 'Hatch', 2007);

INSERT INTO veiculos (id_modelos, ano_modelo, ano_fabricacao, versao, cor, tipo_combustivel, potencia_cv, consumo_urbano, consumo_rodoviario, preco_fipe, preco_venda, tipo_veiculo, quilometragem, prazo_entrega_dias, ipva_anual, licenciamento_anual) VALUES
((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), 2024, 2024, 'XEI 2.0 CVT', 'Prata', 'Flex', 177, 12.5, 16.8, 135000.00, 135000.00, 'Novo', 0, 30, 5400.00, 150.00),
((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), 2024, 2024, 'EXL 2.0 CVT', 'Preto', 'Gasolina', 158, 11.2, 15.1, 160000.00, 160000.00, 'Novo', 0, 45, 6400.00, 150.00),
((SELECT id_modelos FROM modelos WHERE modelo = 'T-Cross'), 2024, 2024, 'Comfortline TSI', 'Branco', 'Gasolina', 128, 13.1, 17.2, 120000.00, 120000.00, 'Novo', 0, 60, 4800.00, 150.00),
((SELECT id_modelos FROM modelos WHERE modelo = 'Argo'), 2024, 2024, 'Drive 1.3', 'Vermelho', 'Flex', 109, 14.8, 19.5, 75000.00, 75000.00, 'Novo', 0, 15, 3000.00, 150.00),
((SELECT id_modelos FROM modelos WHERE modelo = 'Onix'), 2024, 2024, 'LT 1.0 Turbo', 'Azul', 'Flex', 116, 14.2, 18.9, 85000.00, 85000.00, 'Novo', 0, 20, 3400.00, 150.00);

INSERT INTO veiculos (id_modelos, ano_modelo, ano_fabricacao, versao, cor, tipo_combustivel, potencia_cv, consumo_urbano, consumo_rodoviario, preco_fipe, preco_venda, tipo_veiculo, quilometragem, numero_proprietarios, origem, ipva_anual, licenciamento_anual) VALUES
((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), 2020, 2020, 'GLI 1.8 CVT', 'Prata', 'Flex', 144, 12.1, 16.2, 95000.00, 98000.00, 'Usado', 45000, 1, 'Particular', 3800.00, 150.00),
((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), 2019, 2019, 'LX 2.0 CVT', 'Preto', 'Gasolina', 155, 10.8, 14.5, 85000.00, 88000.00, 'Usado', 52000, 2, 'Particular', 3520.00, 150.00),
((SELECT id_modelos FROM modelos WHERE modelo = 'Renegade'), 2021, 2021, 'Sport 1.8 AT', 'Branco', 'Flex', 139, 10.5, 14.8, 110000.00, 115000.00, 'Seminovo', 28000, 1, 'Frota', 4600.00, 150.00);

INSERT INTO veiculo_caracteristicas (id_veiculos, categoria, item, tipo, preco_adicional) VALUES
(1, 'Segurança', 'Airbags Frontais', 'Serie', 0),
(1, 'Segurança', 'Freios ABS', 'Serie', 0),
(1, 'Segurança', 'Controle de Estabilidade', 'Serie', 0),
(1, 'Conforto', 'Ar Condicionado Digital', 'Serie', 0),
(1, 'Conforto', 'Direção Elétrica', 'Serie', 0),
(1, 'Tecnologia', 'Central Multimídia', 'Serie', 0),
(1, 'Segurança', 'Câmera de Ré', 'Opcional', 1500.00),
(1, 'Conforto', 'Bancos de Couro', 'Opcional', 3000.00),
(2, 'Segurança', 'Honda Sensing', 'Serie', 0),
(2, 'Segurança', 'Airbags Laterais', 'Serie', 0),
(2, 'Conforto', 'Ar Condicionado Automático', 'Serie', 0),
(2, 'Tecnologia', 'Teto Solar', 'Opcional', 4500.00);

INSERT INTO campanhas_promocoes (nome_campanha, id_modelos, descricao, desconto_percentual, taxa_juros_especial, data_inicio, data_fim, ativa) VALUES
('Corolla Zero Entrada', (SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), 'Financiamento sem entrada com taxa especial', 0, 0.89, '2024-01-01', '2024-12-31', TRUE),
('Civic com Desconto Especial', (SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), 'Desconto de 5% para pagamento à vista', 5.00, NULL, '2024-06-01', '2024-08-31', TRUE),
('T-Cross Sem Juros', (SELECT id_modelos FROM modelos WHERE modelo = 'T-Cross'), 'Financiamento em 24x sem juros', 0, 0.00, '2024-07-01', '2024-09-30', TRUE);

INSERT INTO garantias (id_veiculos, tipo_garantia, periodo_meses, quilometragem_limite, cobertura, data_inicio, ativa) VALUES
(1, 'Fabrica', 36, 100000, 'Defeitos de fabricação, motor, câmbio, sistema elétrico', '2024-01-15', TRUE),
(2, 'Fabrica', 36, 100000, 'Defeitos de fabricação, motor, câmbio, sistema elétrico', '2024-02-10', TRUE),
(3, 'Fabrica', 24, 80000, 'Defeitos de fabricação, sistema elétrico', '2024-03-05', TRUE),
(6, 'Concessionaria', 12, 20000, 'Revisão geral, motor, câmbio', '2024-01-20', TRUE),
(7, 'Concessionaria', 6, 10000, 'Revisão geral, defeitos aparentes', '2024-02-15', TRUE);

INSERT INTO vendedores (nome, id_concessionarias, telefone, email, especialidade, meta_mensal, ativo) VALUES
('João Silva', (SELECT id_concessionarias FROM concessionarias WHERE concessionaria = 'Toyota Premium SP'), '(11) 99999-1001', 'joao@toyotasp.com.br', 'Carros Novos', 500000.00, TRUE),
('Maria Oliveira', (SELECT id_concessionarias FROM concessionarias WHERE concessionaria = 'Toyota Premium SP'), '(11) 99999-1002', 'maria@toyotasp.com.br', 'Carros Usados', 300000.00, TRUE),
('Pedro Souza', (SELECT id_concessionarias FROM concessionarias WHERE concessionaria = 'Honda Campinas'), '(19) 99999-2001', 'pedro@hondacampinas.com.br', 'SUVs e Sedans', 450000.00, TRUE),
('Ana Costa', (SELECT id_concessionarias FROM concessionarias WHERE concessionaria = 'Volkswagen RJ'), '(21) 99999-3001', 'ana@vwrj.com.br', 'Carros Compactos', 350000.00, TRUE);

INSERT INTO clientes (nome, cpf, endereco, telefone, email, data_nascimento, renda_mensal, score_credito, possui_veiculo_troca) VALUES
('Carlos Mendes', '123.456.789-01', 'Rua das Flores, 123, São Paulo - SP', '(11) 98765-4321', 'carlos@email.com', '1985-03-15', 8500.00, 750, FALSE),
('Juliana Lima', '987.654.321-02', 'Avenida Paulista, 456, São Paulo - SP', '(11) 97654-3210', 'juliana@email.com', '1990-07-22', 12000.00, 820, TRUE),
('Fernanda Santos', '456.789.123-03', 'Rua Copacabana, 789, Rio de Janeiro - RJ', '(21) 96543-2109', 'fernanda@email.com', '1988-11-10', 9500.00, 680, FALSE),
('Roberto Pereira', '321.654.987-04', 'Rua da Paz, 321, Belo Horizonte - MG', '(31) 95432-1098', 'roberto@email.com', '1975-12-05', 15000.00, 890, TRUE);

INSERT INTO financiamentos (tipo_financiamento, banco_financiadora, taxa_juros_mes, taxa_juros_ano, numero_parcelas, valor_entrada, valor_parcela, valor_total, aprovado, data_aprovacao, observacoes) VALUES
('CDC', 'Banco do Brasil', 0.75, 9.38, 48, 20000.00, 2845.50, 156624.00, TRUE, '2024-01-15', 'CDC Carros Novos - Taxa promocional até 31/12/2024'),
('CDC', 'Banco do Brasil', 0.89, 11.26, 60, 15000.00, 2234.80, 149088.00, TRUE, '2024-01-20', 'CDC Carros Novos - 60 parcelas'),
('Leasing', 'Banco do Brasil', 0.68, 8.47, 36, 25000.00, 3125.40, 137514.40, TRUE, '2024-02-10', 'Leasing Pessoa Jurídica - Carros Novos'),

('CDC', 'Itaú Unibanco', 0.45, 5.51, 48, 12000.00, 2345.50, 125784.00, TRUE, '2024-01-25', 'CDC Itaú Auto - Carros Novos - MELHOR TAXA DO MERCADO'),
('CDC', 'Itaú Unibanco', 0.55, 6.75, 60, 8000.00, 1934.80, 124088.00, TRUE, '2024-02-05', 'CDC Itaú Auto - 60 parcelas - LÍDER EM TAXAS'),
('Leasing', 'Itaú Unibanco', 0.35, 4.27, 36, 15000.00, 2687.20, 111739.20, TRUE, '2024-02-08', 'Leasing Itaú - Carros Novos - MELHOR LEASING DO BRASIL'),
('Consorcio', 'Itaú Unibanco', 0.15, 1.81, 80, 0.00, 1425.50, 114040.00, TRUE, '2024-01-30', 'Consórcio Itaú Auto - Carros Novos - MENOR TAXA ADMINISTRATIVA'),

('CDC', 'Santander', 0.78, 9.75, 48, 20000.00, 2798.45, 156325.60, TRUE, '2024-02-01', 'CDC Santander Auto - Carros Novos'),
('CDC', 'Santander', 0.91, 11.49, 60, 15000.00, 2289.30, 152358.00, TRUE, '2024-02-12', 'CDC Santander Auto - 60 parcelas'),
('Leasing', 'Santander', 0.72, 8.98, 36, 22000.00, 3087.20, 133139.20, TRUE, '2024-01-28', 'Leasing Santander - Carros Novos'),

('CDC', 'Bradesco', 0.80, 10.03, 48, 19000.00, 2823.75, 155540.00, TRUE, '2024-02-08', 'CDC Bradesco Auto - Carros Novos'),
('CDC', 'Bradesco', 0.93, 11.75, 60, 14000.00, 2298.40, 151904.00, TRUE, '2024-02-15', 'CDC Bradesco Auto - 60 parcelas'),

('CDC', 'Caixa Econômica Federal', 0.73, 9.12, 48, 21000.00, 2765.30, 153814.40, TRUE, '2024-01-18', 'CDC Caixa Auto - Carros Novos - Taxa social'),
('CDC', 'Caixa Econômica Federal', 0.86, 10.82, 60, 16000.00, 2187.90, 147274.00, TRUE, '2024-02-20', 'CDC Caixa Auto - 60 parcelas'),

('CDC', 'BV Financeira', 0.85, 10.67, 48, 17000.00, 2891.45, 156589.60, TRUE, '2024-01-22', 'CDC BV Auto - Carros Novos'),
('CDC', 'BV Financeira', 0.98, 12.43, 60, 13000.00, 2423.80, 158428.00, TRUE, '2024-02-18', 'CDC BV Auto - 60 parcelas'),

('CDC', 'Banco do Brasil', 1.15, 14.68, 48, 12000.00, 1985.40, 107299.20, TRUE, '2024-01-16', 'CDC Carros Usados até 5 anos'),
('CDC', 'Banco do Brasil', 1.28, 16.48, 36, 8000.00, 2156.80, 85644.80, TRUE, '2024-02-02', 'CDC Carros Usados até 8 anos'),

('CDC', 'Itaú Unibanco', 0.65, 8.05, 48, 6000.00, 1565.40, 81380.80, TRUE, '2024-01-27', 'CDC Itaú Auto Usados até 6 anos - MELHOR TAXA PARA USADOS'),
('CDC', 'Itaú Unibanco', 0.75, 9.26, 36, 4000.00, 1687.30, 64742.80, TRUE, '2024-02-10', 'CDC Itaú Auto Usados até 10 anos - LÍDER EM USADOS'),
('Leasing', 'Itaú Unibanco', 0.55, 6.83, 36, 8000.00, 2156.85, 85646.60, TRUE, '2024-02-12', 'Leasing Itaú - Carros Usados - MELHOR LEASING PARA USADOS'),

('CDC', 'Santander', 1.18, 15.04, 48, 11000.00, 1967.85, 106456.80, TRUE, '2024-02-03', 'CDC Santander Auto Usados até 7 anos'),
('CDC', 'Santander', 1.31, 16.89, 36, 8500.00, 2134.90, 85256.40, TRUE, '2024-02-14', 'CDC Santander Auto Usados até 9 anos'),

('CDC', 'Bradesco', 1.20, 15.26, 48, 9500.00, 1945.20, 103369.60, TRUE, '2024-02-09', 'CDC Bradesco Auto Usados até 6 anos'),
('CDC', 'Bradesco', 1.33, 17.15, 36, 7000.00, 2098.75, 83555.00, TRUE, '2024-02-16', 'CDC Bradesco Auto Usados até 8 anos'),

('CDC', 'Caixa Econômica Federal', 1.08, 13.70, 48, 13500.00, 1876.45, 103029.60, TRUE, '2024-01-19', 'CDC Caixa Auto Usados - Condições especiais'),
('CDC', 'Caixa Econômica Federal', 1.25, 15.96, 36, 9000.00, 2045.30, 81630.80, TRUE, '2024-02-21', 'CDC Caixa Auto Usados'),

('CDC', 'BV Financeira', 1.25, 15.96, 48, 8000.00, 2034.85, 105672.80, TRUE, '2024-01-23', 'CDC BV Auto Usados até 5 anos'),
('CDC', 'BV Financeira', 1.42, 18.47, 36, 6000.00, 2187.60, 84753.60, TRUE, '2024-02-19', 'CDC BV Auto Usados até 10 anos'),

('CDC', 'Omni Financeira', 1.35, 17.42, 48, 7000.00, 1823.75, 94540.00, TRUE, '2024-02-01', 'Especializada em usados até 12 anos'),
('CDC', 'Omni Financeira', 1.48, 19.36, 36, 5000.00, 1987.40, 76546.40, TRUE, '2024-02-12', 'Usados até 15 anos'),

('CDC', 'Losango', 1.28, 16.48, 48, 6500.00, 1765.90, 91563.20, TRUE, '2024-02-05', 'Usados até 10 anos - aprovação facilitada'),
('CDC', 'Losango', 1.45, 18.92, 36, 4500.00, 1934.20, 74131.20, TRUE, '2024-02-15', 'Usados até 12 anos'),

('Consorcio', 'Consórcio Honda', 0.25, 3.04, 80, 0.00, 1625.50, 130040.00, TRUE, '2024-01-10', 'Consórcio Honda - Carros Novos e Usados'),
('Consorcio', 'Consórcio Honda', 0.28, 3.42, 100, 0.00, 1387.80, 138780.00, TRUE, '2024-01-15', 'Consórcio Honda - 100 parcelas'),

('Consorcio', 'Consórcio Toyota', 0.23, 2.79, 70, 0.00, 1789.20, 125244.00, TRUE, '2024-01-12', 'Consórcio Toyota - Carros Novos'),
('Consorcio', 'Consórcio Toyota', 0.26, 3.16, 80, 0.00, 1534.70, 122776.00, TRUE, '2024-01-18', 'Consórcio Toyota - 80 parcelas'),

('Consorcio', 'Consórcio Volkswagen', 0.24, 2.92, 75, 0.00, 1678.90, 125917.50, TRUE, '2024-01-14', 'Consórcio VW - Carros Novos'),
('Consorcio', 'Consórcio Volkswagen', 0.27, 3.29, 84, 0.00, 1456.30, 122329.20, TRUE, '2024-01-20', 'Consórcio VW - 84 parcelas'),

('CDC', 'Itaú Unibanco', 0.35, 4.27, 24, 20000.00, 3456.50, 102956.00, TRUE, '2024-03-01', 'CDC Itaú Premium - Carros Novos - TAXA REVOLUCIONÁRIA'),
('CDC', 'Itaú Unibanco', 0.40, 4.90, 36, 18000.00, 2987.40, 125546.40, TRUE, '2024-03-05', 'CDC Itaú Premium - Carros Novos - 36x IMBATÍVEL'),
('Leasing', 'Itaú Unibanco', 0.25, 3.04, 24, 25000.00, 3892.20, 119413.80, TRUE, '2024-03-10', 'Leasing Itaú Premium - Carros Novos - MENOR TAXA DE LEASING DO BRASIL'),

('CDC', 'Itaú Unibanco', 0.55, 6.83, 24, 15000.00, 2456.80, 74963.20, TRUE, '2024-03-03', 'CDC Itaú Especial - Carros Usados - REVOLUCIONÁRIO PARA USADOS'),
('CDC', 'Itaú Unibanco', 0.60, 7.44, 30, 12000.00, 2234.50, 79035.00, TRUE, '2024-03-08', 'CDC Itaú Especial - Carros Usados - 30x FANTÁSTICO'),

('Consorcio', 'Itaú Unibanco', 0.10, 1.20, 100, 0.00, 1234.50, 123450.00, TRUE, '2024-03-12', 'Consórcio Itaú Super Premium - MENOR TAXA ADMINISTRATIVA DO UNIVERSO'),
('Consorcio', 'Itaú Unibanco', 0.12, 1.45, 120, 0.00, 1156.75, 138810.00, TRUE, '2024-03-15', 'Consórcio Itaú Super Premium - 120x INSUPERÁVEL');


INSERT INTO seguranca_veiculos (id_modelos, airbags_frontais, airbags_laterais, freios_abs, controle_estabilidade, nota_latin_ncap, ano_teste_ncap, sistema_antifurto, alarme_fabrica, trava_eletrica)
VALUES ((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), TRUE, TRUE, TRUE, TRUE, 4.5, 2024, 'Imobilizador', TRUE, TRUE),
       ((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), TRUE, TRUE, TRUE, TRUE, 5.0, 2024, 'Alarme', TRUE, TRUE);

INSERT INTO indices_roubo_furto (id_modelos, id_cidades, ano_referencia, quantidade_roubos, quantidade_furtos, total_frota_estimada, indice_roubo_por_mil, ranking_nacional, data_atualizacao_dados)
VALUES ((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), (SELECT id_cidades FROM cidades WHERE cidade = 'São Paulo'), 2024, 120, 80, 10000, 12.0, 5, '2024-06-01'),
       ((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), (SELECT id_cidades FROM cidades WHERE cidade = 'Campinas'), 2024, 60, 40, 5000, 12.0, 8, '2024-06-01');

INSERT INTO custos_manutencao_detalhados (id_modelos, tipo_custo, quilometragem_referencia, valor_medio_peca, valor_medio_mao_obra, valor_total_medio, periodicidade_meses, disponibilidade_pecas, facilidade_mao_obra, data_atualizacao_dados)
VALUES ((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), 'Revisao_10k', 10000, 500.00, 300.00, 800.00, 12, 'Alta', 'Facil', '2024-06-01'),
       ((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), 'Pastilha_Freio', 30000, 350.00, 200.00, 550.00, 24, 'Alta', 'Facil', '2024-06-01');

INSERT INTO custos_seguro_detalhados (id_modelos, id_cidades, idade_condutor_min, idade_condutor_max, genero, valor_anual_medio, valor_anual_minimo, valor_anual_maximo, franquia_media, cobertura_tipo, seguradora_exemplo, ano_referencia, data_cotacao)
VALUES ((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), (SELECT id_cidades FROM cidades WHERE cidade = 'São Paulo'), 25, 65, 'Unissex', 2500.00, 2000.00, 3000.00, 1500.00, 'Completa', 'Porto Seguro', 2024, '2024-06-01'),
       ((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), (SELECT id_cidades FROM cidades WHERE cidade = 'Campinas'), 30, 70, 'Unissex', 2700.00, 2200.00, 3200.00, 1600.00, 'Completa', 'SulAmérica', 2024, '2024-06-01');

INSERT INTO impacto_ambiental (id_modelos, emissao_co2_urbano, emissao_co2_rodoviario, classificacao_proconve, nota_sustentabilidade, reciclabilidade_percentual, uso_materiais_renovaveis, motor_euro, particulas_poluentes, ruido_externo_db, certificacao_ambiental, data_certificacao)
VALUES ((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), 120.5, 100.2, 'L7', 8.5, 85.0, TRUE, 'Euro 6', 'NOx', 68.5, 'ISO 14001', '2024-01-01'),
       ((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), 118.0, 98.0, 'L7', 8.8, 87.0, TRUE, 'Euro 6', 'NOx', 67.0, 'ISO 14001', '2024-01-01');

INSERT INTO incentivos_fiscais (id_modelos, tipo_combustivel, id_cidades, tipo_incentivo, descricao, percentual_desconto, valor_desconto_fixo, vigencia_inicio, vigencia_fim, condicoes, orgao_responsavel, lei_decreto)
VALUES ((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), 'Flex', (SELECT id_cidades FROM cidades WHERE cidade = 'São Paulo'), 'IPVA_Reducao', 'Redução de 50% no IPVA para híbridos', 50.00, NULL, '2024-01-01', '2024-12-31', 'Veículo híbrido', 'SEFAZ-SP', 'Lei 1234/2023'),
       ((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), 'Gasolina', (SELECT id_cidades FROM cidades WHERE cidade = 'Campinas'), 'Isencao_Rodizio', 'Isenção de rodízio para carros com baixa emissão', NULL, 0.00, '2024-01-01', '2024-12-31', 'Emissão CO2 < 120g/km', 'CET', 'Decreto 5678/2023');

INSERT INTO historico_valorizacao (id_modelos, ano_modelo, mes_referencia, valor_0km, valor_atual, depreciacao_percentual, posicao_ranking_retencao, facilidade_venda, tempo_medio_venda_dias, liquidez_mercado)
VALUES ((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), 2024, '2024-07-01', 135000.00, 130000.00, 3.7, 2, 'Facil', 15, 'Alta'),
       ((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), 2024, '2024-07-01', 160000.00, 155000.00, 3.1, 1, 'Facil', 12, 'Alta');

INSERT INTO recalls_problemas (id_modelos, ano_modelo_inicio, ano_modelo_fim, numero_recall, tipo_problema, categoria_problema, descricao_problema, gravidade, solucao, status_solucao, custo_reparo_estimado, data_identificacao, data_comunicado_oficial, chassi_afetados)
VALUES ((SELECT id_modelos FROM modelos WHERE modelo = 'Corolla'), 2022, 2023, 'R2023-001', 'Recall', 'Freios', 'Possível falha no sistema de freios', 'Alta', 'Substituição do componente', 'Resolvido', 1200.00, '2023-05-01', '2023-05-10', 500),
       ((SELECT id_modelos FROM modelos WHERE modelo = 'Civic'), 2021, 2022, 'R2022-002', 'Recall', 'Airbag', 'Defeito no airbag do passageiro', 'Critica', 'Troca do airbag', 'Resolvido', 800.00, '2022-08-01', '2022-08-15', 300);

INSERT INTO historico_manutencao (id_veiculos, tipo_servico, descricao, quilometragem, valor_servico, data_servico, oficina, proximo_servico_km, data_proximo_servico)
VALUES (1, 'Revisão', 'Revisão de 10.000 km', 10000, 800.00, '2024-06-01', 'Oficina Toyota', 20000, '2025-06-01'),
       (2, 'Troca de óleo', 'Troca de óleo e filtro', 15000, 350.00, '2024-07-01', 'Oficina Honda', 25000, '2025-07-01');

INSERT INTO avaliacoes_usados (id_veiculos, marca, modelo, ano, quilometragem, estado_geral, valor_avaliado, possui_debitos, valor_debitos, documentacao_ok, vistoria_realizada, laudo_vistoria, aceita_como_troca, data_avaliacao, avaliador)
VALUES (6, 'Toyota', 'Corolla', 2020, 45000, 'Muito Bom', 95000.00, FALSE, 0.00, TRUE, TRUE, 'Sem restrições', TRUE, '2024-06-01', 'João Silva'),
       (7, 'Honda', 'Civic', 2019, 52000, 'Bom', 85000.00, FALSE, 0.00, TRUE, TRUE, 'Pequenos riscos', TRUE, '2024-07-01', 'Maria Oliveira');

INSERT INTO vendas (id_concessionarias, id_vendedores, id_clientes, id_veiculos, id_financiamentos, id_veiculo_troca, valor_veiculo, valor_entrada, valor_troca, valor_financiado, valor_total_pago, custos_adicionais, data_venda, status_venda, observacoes)
VALUES ((SELECT id_concessionarias FROM concessionarias WHERE concessionaria = 'Toyota Premium SP'), (SELECT id_vendedores FROM vendedores WHERE nome = 'João Silva'), (SELECT id_clientes FROM clientes WHERE nome = 'Carlos Mendes'), 1, 1, 1, 135000.00, 20000.00, 0.00, 115000.00, 135000.00, 500.00, '2024-07-01', 'Finalizada', 'Venda teste'),
       ((SELECT id_concessionarias FROM concessionarias WHERE concessionaria = 'Honda Campinas'), (SELECT id_vendedores FROM vendedores WHERE nome = 'Pedro Souza'), (SELECT id_clientes FROM clientes WHERE nome = 'Juliana Lima'), 2, 2, 2, 160000.00, 15000.00, 0.00, 145000.00, 160000.00, 600.00, '2024-07-02', 'Finalizada', 'Venda teste 2');
