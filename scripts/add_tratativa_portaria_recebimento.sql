-- Tratativa das notas da portaria: o líder classifica o tipo (retirada x
-- lançamento), escreve uma observação e, quando for lançamento, valida que
-- foi lançado no SAP.
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar.

ALTER TABLE portaria_recebimento
  ADD COLUMN IF NOT EXISTS tipo            text,
  ADD COLUMN IF NOT EXISTS tratativa       text,
  ADD COLUMN IF NOT EXISTS sap_lancado     boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sap_lancado_por text,
  ADD COLUMN IF NOT EXISTS sap_lancado_em  timestamptz;

ALTER TABLE portaria_recebimento
  DROP CONSTRAINT IF EXISTS portaria_recebimento_tipo_check;
ALTER TABLE portaria_recebimento
  ADD CONSTRAINT portaria_recebimento_tipo_check CHECK (tipo IS NULL OR tipo IN ('retirada','lancamento'));
