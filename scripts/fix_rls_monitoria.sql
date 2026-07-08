-- ── Corrige "new row violates row-level security policy for table monitoria_registros" ──
-- O Monitor não consegue salvar monitoria: a tabela tem RLS ligado mas a
-- policy atual não libera o INSERT pra sessão autenticada (não é problema de
-- conexão com o Supabase — a conexão chega, o banco é quem recusa a escrita).
-- Mesmo ajuste já usado em outras tabelas do app (checklist_33,
-- instrutor_atribuicoes): autenticado pode tudo, sem restrição por dono.
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar.

-- monitoria_registros — usada em app-mobile.html (monMobSalvarMonitoria)
ALTER TABLE monitoria_registros ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON monitoria_registros;
CREATE POLICY "Autenticado pode tudo"
  ON monitoria_registros FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON monitoria_registros TO authenticated;

-- monitor_relatorio_carro — mesmo fluxo do Monitor, checklist do carro
ALTER TABLE monitor_relatorio_carro ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON monitor_relatorio_carro;
CREATE POLICY "Autenticado pode tudo"
  ON monitor_relatorio_carro FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON monitor_relatorio_carro TO authenticated;

-- monitor_relatorio_linha — mesmo fluxo do Monitor, checklist da linha
ALTER TABLE monitor_relatorio_linha ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Autenticado pode tudo" ON monitor_relatorio_linha;
CREATE POLICY "Autenticado pode tudo"
  ON monitor_relatorio_linha FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
GRANT ALL ON monitor_relatorio_linha TO authenticated;
