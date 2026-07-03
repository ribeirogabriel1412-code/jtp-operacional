-- ── Painel Preventivas — Histórico no Supabase ──────────────────────────────
-- Rode este arquivo no Supabase SQL Editor.
-- Move para o banco o que hoje só fica salvo no localStorage do navegador:
-- semanas consolidadas, importações do PDF MAN e valetamento.
-- Seguro re-executar (IF NOT EXISTS / OR REPLACE).

-- 1. Semanas consolidadas (escala da semana: pesadas/leves por dia)
CREATE TABLE IF NOT EXISTS preventiva_semanas (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  semana_key      text NOT NULL,
  inicio          date,
  fim             date,
  inicio_br       text,
  fim_br          text,
  dias            jsonb NOT NULL DEFAULT '[]'::jsonb,
  itens           jsonb NOT NULL DEFAULT '[]'::jsonb,
  totais          jsonb NOT NULL DEFAULT '{}'::jsonb,
  importado_em    text,
  criado_por      text,
  criado_em       timestamptz NOT NULL DEFAULT now(),
  atualizado_em   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (garagem_id, semana_key)
);
CREATE INDEX IF NOT EXISTS preventiva_semanas_garagem
  ON preventiva_semanas (garagem_id, inicio DESC);

-- 2. Importações do relatório MAN (histórico de cada PDF importado)
CREATE TABLE IF NOT EXISTS preventiva_importacoes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  arquivo         text,
  total           integer NOT NULL DEFAULT 0,
  pesadas         integer NOT NULL DEFAULT 0,
  leves           integer NOT NULL DEFAULT 0,
  planos          jsonb NOT NULL DEFAULT '[]'::jsonb,
  criado_por      text,
  criado_em       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS preventiva_importacoes_garagem
  ON preventiva_importacoes (garagem_id, criado_em DESC);

-- 3. Valetamento (lista de carros preparados por data)
CREATE TABLE IF NOT EXISTS preventiva_valetamento (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  data            date NOT NULL,
  itens           jsonb NOT NULL DEFAULT '[]'::jsonb,
  criado_por      text,
  criado_em       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (garagem_id, data)
);
CREATE INDEX IF NOT EXISTS preventiva_valetamento_garagem
  ON preventiva_valetamento (garagem_id, data DESC);

-- 4. RLS — habilita e cria política para usuários autenticados (mesmo padrão do resto do app)
ALTER TABLE preventiva_semanas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON preventiva_semanas;
CREATE POLICY "Autenticado pode tudo" ON preventiva_semanas FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

ALTER TABLE preventiva_importacoes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON preventiva_importacoes;
CREATE POLICY "Autenticado pode tudo" ON preventiva_importacoes FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

ALTER TABLE preventiva_valetamento ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON preventiva_valetamento;
CREATE POLICY "Autenticado pode tudo" ON preventiva_valetamento FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
