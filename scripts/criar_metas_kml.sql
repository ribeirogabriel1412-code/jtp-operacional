-- Meta de Km/L por veiculo (importada da planilha oficial CTAPLUS/BI) --
-- Rode este arquivo no Supabase SQL Editor.
-- Usada pra disparar a analise da LLM quando o Km/L real fica abaixo da meta.
-- Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS metas_kml_veiculo (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id  uuid NOT NULL,
  garagem_cod text NOT NULL,
  veiculo     text NOT NULL,
  meta        numeric NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (garagem_cod, veiculo)
);

-- Escrito por script (chave anon, sem sessao autenticada) -- mesmo padrao
-- do praxio_sync/viagens_resumo/instrutor_kml_detalhado.
ALTER TABLE metas_kml_veiculo DISABLE ROW LEVEL SECURITY;
ALTER TABLE metas_kml_veiculo NO FORCE ROW LEVEL SECURITY;
GRANT ALL ON metas_kml_veiculo TO anon;
GRANT ALL ON metas_kml_veiculo TO authenticated;
