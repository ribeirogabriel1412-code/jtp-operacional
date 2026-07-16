-- Fechamento automático diário do Plantão (dobras, absenteísmo, S.O.S., trocas).
-- Alimentada pelo script scripts/fechar_plantao_diario.ps1 (roda às 02:00 via Task Scheduler).
-- Revisar e rodar manualmente no SQL Editor do Supabase.

CREATE TABLE IF NOT EXISTS fechamento_plantao (
  id bigserial PRIMARY KEY,
  garagem_id uuid REFERENCES garagens(id),
  data text NOT NULL,
  total_dobras int NOT NULL DEFAULT 0,
  total_absenteismo int NOT NULL DEFAULT 0,
  total_sos int NOT NULL DEFAULT 0,
  total_sos_nao_resolvidos int NOT NULL DEFAULT 0,
  total_trocas int NOT NULL DEFAULT 0,
  detalhes jsonb,
  gerado_automaticamente boolean NOT NULL DEFAULT true,
  fechado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (garagem_id, data)
);

ALTER TABLE fechamento_plantao ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Autenticado pode tudo" ON fechamento_plantao
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
