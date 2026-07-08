-- Inventário Cíclico de Baixa Rotação -- catálogo + contagens por ciclo
-- Rodar uma vez no SQL Editor do Supabase.

CREATE TABLE almoxo_baixa_rotacao_itens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id uuid NOT NULL,
  cod_sap text NOT NULL,
  nome_item text,
  wms_localizacao text,
  saida_3m numeric,
  estoque_sistema numeric,
  preco_medio numeric,
  valor_estimado_3m numeric,
  ativo boolean NOT NULL DEFAULT true,
  criado_em timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_baixa_rotacao_itens_garagem ON almoxo_baixa_rotacao_itens(garagem_id);

CREATE TABLE almoxo_baixa_rotacao_contagem (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id uuid NOT NULL,
  item_id uuid NOT NULL REFERENCES almoxo_baixa_rotacao_itens(id),
  ciclo int NOT NULL,
  qtd_sistema numeric,
  qtd_fisica numeric NOT NULL,
  acuracia numeric,
  almoxarife_id uuid,
  almoxarife_nome text,
  turno_data date,
  criado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE(item_id, ciclo)
);
CREATE INDEX idx_baixa_rotacao_contagem_garagem_ciclo ON almoxo_baixa_rotacao_contagem(garagem_id, ciclo);
