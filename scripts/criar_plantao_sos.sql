-- Perfil Plantonista: SOS ao vivo (primeiro contato do motorista) --
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS plantao_sos (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id        uuid NOT NULL,
  data              date NOT NULL,
  prefixo           text NOT NULL,
  linha             text,
  motorista         text,
  km                text,
  problema          text NOT NULL,
  decisao           text,          -- 'segue_rodando' | 'troca_carro' | 'troca_motorista' | 'aciona_pcm' | 'outro'
  decisao_detalhe   text,
  status            text NOT NULL DEFAULT 'aberto',  -- 'aberto' | 'encerrado'
  resolucao         text,
  resolvido_em      timestamptz,
  plantao_nome      text,
  plantao_id        uuid,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS plantao_sos_garagem_data
  ON plantao_sos (garagem_id, data);

-- Escrito por usuario logado no app (sessao authenticated) -- RLS ligado com
-- policy explicita liberando tudo. NUNCA usar DISABLE ROW LEVEL SECURITY aqui
-- (ver scripts/fix_rls_monitoria.sql e scripts/fix_rls_plantao_dobras_absenteismo.sql --
-- DISABLE nao segura nesse projeto pra escrita autenticada).
ALTER TABLE plantao_sos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON plantao_sos;
CREATE POLICY "Autenticado pode tudo"
  ON plantao_sos FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON plantao_sos TO authenticated;
