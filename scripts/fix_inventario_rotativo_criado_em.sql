-- ── Fix Inventário Rotativo — adiciona criado_em — 2026-07-14 ───────────────
-- A tabela almoxo_inventario_turno nunca teve coluna de timestamp (foi
-- removida no passado por não existir — ver commit 8f7308c). Sem ela, a 2ª
-- conferência não tem como saber qual foi a ÚLTIMA contagem de um item
-- quando ele é contado em mais de um turno/dia dentro da janela. Rode este
-- arquivo no Supabase SQL Editor.

ALTER TABLE almoxo_inventario_turno
  ADD COLUMN IF NOT EXISTS criado_em timestamptz NOT NULL DEFAULT now();

-- Nota: linhas já existentes vão receber o timestamp do momento em que esse
-- ALTER rodar (todas com o mesmo valor) — não há como recuperar a hora real
-- de contagens antigas. A partir daqui, todo INSERT novo grava o horário
-- real automaticamente pelo DEFAULT, sem precisar mudar o app.

CREATE INDEX IF NOT EXISTS idx_almoxo_inv_turno_criado_em
  ON almoxo_inventario_turno (garagem_id, criado_em DESC);
