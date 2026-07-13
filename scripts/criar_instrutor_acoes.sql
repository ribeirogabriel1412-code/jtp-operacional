-- Plano de ação do Instrutor -- itens de ação que o instrutor monta em cima
-- do que os monitores relataram no dia (Relatório do Dia, aba do Instrutor).
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS instrutor_acoes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id    uuid NOT NULL,
  data          date NOT NULL,
  descricao     text NOT NULL,
  responsavel   text,
  prazo         date,
  status        text NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','concluido')),
  criado_por    text,
  criado_em     timestamptz NOT NULL DEFAULT now(),
  concluido_em  timestamptz
);

CREATE INDEX IF NOT EXISTS instrutor_acoes_garagem_data
  ON instrutor_acoes (garagem_id, data);

ALTER TABLE instrutor_acoes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON instrutor_acoes;
CREATE POLICY "Autenticado pode tudo"
  ON instrutor_acoes FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON instrutor_acoes TO authenticated;
