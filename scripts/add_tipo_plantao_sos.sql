-- Adiciona o tipo de ocorrência (SOS x RA) na tabela plantao_sos --
-- SOS: enviamos socorro até o carro e trazemos pra garagem.
-- RA (Recolha Anormal): o carro com defeito consegue retornar sozinho
--   até a garagem, onde é feita a troca do carro.
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar.

ALTER TABLE plantao_sos
  ADD COLUMN IF NOT EXISTS tipo text NOT NULL DEFAULT 'sos';

ALTER TABLE plantao_sos
  DROP CONSTRAINT IF EXISTS plantao_sos_tipo_check;
ALTER TABLE plantao_sos
  ADD CONSTRAINT plantao_sos_tipo_check CHECK (tipo IN ('sos','ra'));
