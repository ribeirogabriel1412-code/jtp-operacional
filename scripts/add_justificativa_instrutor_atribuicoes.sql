-- Justificativa pros itens do Plano do Dia que o monitor não conseguiu fazer --
-- usado no Relatório do Dia (Instrutor) na seção de Produtividade dos
-- Monitores: planejado x realizado, e o motivo de cada item faltante.
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar.

ALTER TABLE instrutor_atribuicoes
  ADD COLUMN IF NOT EXISTS justificativa text;
