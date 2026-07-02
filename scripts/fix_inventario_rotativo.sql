-- ── Fix Inventário Rotativo — 2026-07-02 ────────────────────────────────────

-- 1. Adiciona entregue_em em requisicoes_compra
--    Usado para filtrar T-1 e Turno Atual pela hora real da entrega
ALTER TABLE requisicoes_compra
  ADD COLUMN IF NOT EXISTS entregue_em timestamptz;

-- 2. Corrige RLS em almoxo_inventario_turno
--    A tabela tinha RLS ativo mas sem policy → bloqueava inserts do app mobile
ALTER TABLE almoxo_inventario_turno ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Almox autenticado" ON almoxo_inventario_turno;
CREATE POLICY "Almox autenticado"
  ON almoxo_inventario_turno FOR ALL
  USING  (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');
