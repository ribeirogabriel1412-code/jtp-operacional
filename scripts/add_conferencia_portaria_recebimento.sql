-- Adiciona a confirmação de entrada (líder de Suprimentos/almox) na tabela
-- portaria_recebimento -- fecha o ciclo: plantão registra a nota na portaria
-- (status='pendente') e o almox confirma que deu entrada (status='conferido').
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar.

ALTER TABLE portaria_recebimento
  ADD COLUMN IF NOT EXISTS conferido_por text,
  ADD COLUMN IF NOT EXISTS conferido_em  timestamptz;
