-- ── Corrige "new row violates row-level security policy for table plantao_dobras" ──
-- Mesmo problema já visto em monitoria_registros/checklist_33/instrutor_atribuicoes
-- (ver fix_rls_monitoria.sql): DISABLE ROW LEVEL SECURITY não segura nesse projeto
-- pra escrita feita por sessão autenticada do app. Padrão que funciona: manter RLS
-- ligado com policy explícita liberando tudo pra authenticated.
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar.

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
