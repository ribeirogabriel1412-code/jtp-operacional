-- ── Tratativa de desvios do Inventário Rotativo (Painel do Líder de Suprimentos) ──
-- Na tela "Inventário Rotativo — Última contagem por item/turno" (index.html,
-- confCruzarRotativo), cada item com desvio (Físico × SAP diferente) agora
-- pode ser classificado pelo líder:
--   recebimento      → material entrou depois da contagem (NF + quantidade)
--   contagem_errada  → físico foi contado errado, líder registra a recontagem
--   desvio           → divergência real, só formaliza — será tratada no
--                       inventário oficial, sem campo extra
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar.

CREATE TABLE IF NOT EXISTS almoxo_inventario_tratativas (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id     uuid NOT NULL,
  cod_sap        text NOT NULL,
  turno_data     date NOT NULL,
  tipo           text NOT NULL CHECK (tipo IN ('recebimento','contagem_errada','desvio')),
  nota_fiscal    text,
  qtd_recebida   numeric,
  qtd_corrigida  numeric,
  observacao     text,
  criado_por     text,
  criado_em      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (garagem_id, cod_sap, turno_data)
);

CREATE INDEX IF NOT EXISTS almoxo_inventario_tratativas_busca
  ON almoxo_inventario_tratativas (garagem_id, turno_data);

ALTER TABLE almoxo_inventario_tratativas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Autenticado pode tudo" ON almoxo_inventario_tratativas;
CREATE POLICY "Autenticado pode tudo"
  ON almoxo_inventario_tratativas FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

GRANT ALL ON almoxo_inventario_tratativas TO authenticated;
