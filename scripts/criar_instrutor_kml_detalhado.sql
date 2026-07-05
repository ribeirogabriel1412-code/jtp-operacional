-- ── Instrutor KM/L Detalhado — granularidade dia + veiculo + motorista + linha ──
-- Rode este arquivo no Supabase SQL Editor.
-- Fonte: Oracle GLOBUS868.VW_LANCAMENTOABASTECIMENTO, via scripts/sync_kml_detalhado.ps1
-- Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS instrutor_kml_detalhado (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  garagem_cod     text NOT NULL,
  data            date NOT NULL,
  veiculo         text NOT NULL,
  placa           text,
  motorista_cod   text,
  motorista_nome  text,
  linha           text,
  linha_nome      text,
  km_percorrido   numeric,
  litros          numeric,
  km_l            numeric,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (garagem_cod, data, veiculo, motorista_cod, linha)
);

CREATE INDEX IF NOT EXISTS instrutor_kml_detalhado_garagem
  ON instrutor_kml_detalhado (garagem_id, data DESC);
CREATE INDEX IF NOT EXISTS instrutor_kml_detalhado_veiculo
  ON instrutor_kml_detalhado (garagem_id, veiculo, data DESC);

-- Escrito por script PowerShell (chave anon, sem sessao autenticada) --
-- mesmo padrao do viagens_resumo/praxio: desabilita RLS, concede a anon.
ALTER TABLE instrutor_kml_detalhado DISABLE ROW LEVEL SECURITY;
ALTER TABLE instrutor_kml_detalhado NO FORCE ROW LEVEL SECURITY;
GRANT ALL ON instrutor_kml_detalhado TO anon;
GRANT ALL ON instrutor_kml_detalhado TO authenticated;
