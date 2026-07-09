-- Perfil Plantonista: registro estruturado de Dobras e Absenteismo --
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS plantao_dobras (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  data            date NOT NULL,
  motorista       text NOT NULL,
  prefixo         text,
  linha           text,
  motivo          text,          -- 'cobertura_falta' | 'reforco' | 'outro'
  autorizado_por  text,
  plantao_nome    text,
  plantao_id      uuid,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS plantao_dobras_garagem_data
  ON plantao_dobras (garagem_id, data);

CREATE TABLE IF NOT EXISTS plantao_absenteismo (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id          uuid NOT NULL,
  data                date NOT NULL,
  motorista           text NOT NULL,
  linha               text,
  prefixo             text,
  motivo              text NOT NULL,   -- 'falta_injustificada' | 'atestado' | 'atraso' | 'outro'
  cobertura           text,            -- 'reserva' | 'dobra' | 'sem_cobertura'
  cobertura_motorista text,
  plantao_nome        text,
  plantao_id          uuid,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS plantao_absenteismo_garagem_data
  ON plantao_absenteismo (garagem_id, data);

-- Escrito por usuario logado no app (sessao authenticated) -- RLS ligado com
-- policy explicita liberando tudo, mesmo padrao ja usado em monitoria_registros
-- checklist_33, instrutor_atribuicoes (ver fix_rls_monitoria.sql).
ALTER TABLE plantao_dobras ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON plantao_dobras;
CREATE POLICY "Autenticado pode tudo"
  ON plantao_dobras FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON plantao_dobras TO authenticated;

ALTER TABLE plantao_absenteismo ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON plantao_absenteismo;
CREATE POLICY "Autenticado pode tudo"
  ON plantao_absenteismo FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON plantao_absenteismo TO authenticated;
