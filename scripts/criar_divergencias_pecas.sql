-- Divergencias entre requisicoes_compra (nosso app) e a Oracle/PRAXIO --
-- Rode este arquivo no Supabase SQL Editor.
-- Alimentada por scripts/sync_divergencias_pecas.ps1 (roda no servidor,
-- agendado no Task Scheduler). Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS divergencias_pecas_praxio (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  requisicao_id   bigint,
  os_numero       text NOT NULL,
  prefixo         text,
  cod_sap         text,
  peca            text,
  qtd_app         numeric,
  qtd_oracle      numeric,
  tipo_divergencia text NOT NULL,  -- 'sem_match_oracle' | 'qtd_diferente' | 'sem_match_app'
  detalhe         text,
  detectado_em    timestamptz NOT NULL DEFAULT now(),
  resolvido       boolean NOT NULL DEFAULT false,
  UNIQUE (os_numero, cod_sap, tipo_divergencia)
);

CREATE INDEX IF NOT EXISTS divergencias_pecas_praxio_garagem
  ON divergencias_pecas_praxio (garagem_id, resolvido, detectado_em DESC);

-- Escrito por script (chave anon, sem sessao autenticada) -- mesmo padrao
-- das outras tabelas de sync deste projeto.
ALTER TABLE divergencias_pecas_praxio DISABLE ROW LEVEL SECURITY;
ALTER TABLE divergencias_pecas_praxio NO FORCE ROW LEVEL SECURITY;
GRANT ALL ON divergencias_pecas_praxio TO anon;
GRANT ALL ON divergencias_pecas_praxio TO authenticated;
