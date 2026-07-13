-- Entrada de material na portaria (registrado pelo plantonista) --
-- O plantonista recebe o material do fornecedor na portaria e registra
-- nota fiscal, fornecedor e o que foi entregue. status='pendente' fica
-- disponível pro almoxarifado conferir depois (integração futura).
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS portaria_recebimento (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id    uuid NOT NULL,
  data          date NOT NULL,
  numero_nota   text NOT NULL,
  fornecedor    text NOT NULL,
  material      text NOT NULL,
  status        text NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','conferido')),
  plantao_nome  text,
  plantao_id    uuid,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS portaria_recebimento_garagem_data
  ON portaria_recebimento (garagem_id, data);

-- Escrito por usuario logado no app (sessao authenticated) -- RLS ligado com
-- policy explicita liberando tudo. NUNCA usar DISABLE ROW LEVEL SECURITY aqui.
ALTER TABLE portaria_recebimento ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON portaria_recebimento;
CREATE POLICY "Autenticado pode tudo"
  ON portaria_recebimento FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON portaria_recebimento TO authenticated;
