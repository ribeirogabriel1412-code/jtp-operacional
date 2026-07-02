-- ── Fix Inventário Rotativo — 2026-07-02 ────────────────────────────────────

-- 1. Adiciona entregue_em em requisicoes_compra
--    Usado para filtrar T-1 e Turno Atual pela hora real da entrega
ALTER TABLE requisicoes_compra
  ADD COLUMN IF NOT EXISTS entregue_em timestamptz;

-- 3. Adiciona separado_por em requisicoes_compra
--    UUID do almox que confirmou a entrega — discriminador T-1 vs Turno Atual
--    (elimina fragilidade da janela de horário de turno)
ALTER TABLE requisicoes_compra
  ADD COLUMN IF NOT EXISTS separado_por uuid;

-- 2. Corrige RLS em almoxo_inventario_turno
--    A tabela tinha RLS ativo mas sem policy → bloqueava inserts do app mobile
ALTER TABLE almoxo_inventario_turno ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Almox autenticado" ON almoxo_inventario_turno;
CREATE POLICY "Almox autenticado"
  ON almoxo_inventario_turno FOR ALL
  USING  (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');
