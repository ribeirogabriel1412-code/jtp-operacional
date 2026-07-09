-- Perfil Plantonista: troca de carro/motorista de linha (fora do fluxo de soltura) --
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS plantao_trocas (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  data            date NOT NULL,
  tipo            text NOT NULL,   -- 'carro' | 'motorista'
  prefixo         text NOT NULL,   -- carro da linha afetada
  linha           text,
  original        text NOT NULL,   -- prefixo antigo OU motorista antigo
  substituto      text NOT NULL,   -- prefixo novo OU motorista novo
  motivo          text,
  autorizado_por  text,
  plantao_nome    text,
  plantao_id      uuid,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS plantao_trocas_garagem_data
  ON plantao_trocas (garagem_id, data);

-- Escrito por usuario logado no app (sessao authenticated) -- RLS ligado com
-- policy explicita liberando tudo. NUNCA usar DISABLE ROW LEVEL SECURITY aqui
-- (ver scripts/fix_rls_monitoria.sql e scripts/fix_rls_plantao_dobras_absenteismo.sql).
ALTER TABLE plantao_trocas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON plantao_trocas;
CREATE POLICY "Autenticado pode tudo"
  ON plantao_trocas FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON plantao_trocas TO authenticated;
