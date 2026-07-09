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

-- Mesmo padrao das outras tabelas do app: chave anon, sem sessao autenticada.
ALTER TABLE plantao_dobras DISABLE ROW LEVEL SECURITY;
ALTER TABLE plantao_dobras NO FORCE ROW LEVEL SECURITY;
GRANT ALL ON plantao_dobras TO anon;
GRANT ALL ON plantao_dobras TO authenticated;

ALTER TABLE plantao_absenteismo DISABLE ROW LEVEL SECURITY;
ALTER TABLE plantao_absenteismo NO FORCE ROW LEVEL SECURITY;
GRANT ALL ON plantao_absenteismo TO anon;
GRANT ALL ON plantao_absenteismo TO authenticated;
