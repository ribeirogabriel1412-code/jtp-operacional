-- Programacao semanal fixa dos monitores (Instrutor monta uma vez, vale toda
-- semana) -- substitui o "escalar item por item toda hora" por um padrao
-- reconhecivel: monitor X faz campo segunda a sexta, monitor Y faz linha
-- terca e quinta, etc. Rode este arquivo no Supabase SQL Editor.

CREATE TABLE IF NOT EXISTS monitor_escala_semanal (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id    uuid NOT NULL,
  monitor_id    uuid NOT NULL,
  monitor_nome  text,
  dia_semana    smallint NOT NULL,  -- 0=domingo, 1=segunda, ..., 6=sabado
  tipo          text NOT NULL,      -- 'campo' | 'linha' | 'carro'
  criado_por    text,
  criado_em     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (garagem_id, monitor_id, dia_semana, tipo)
);

CREATE INDEX IF NOT EXISTS monitor_escala_semanal_garagem
  ON monitor_escala_semanal (garagem_id, dia_semana);

ALTER TABLE monitor_escala_semanal ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS monitor_escala_semanal_all ON monitor_escala_semanal;
CREATE POLICY monitor_escala_semanal_all ON monitor_escala_semanal
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT ALL ON monitor_escala_semanal TO authenticated;
