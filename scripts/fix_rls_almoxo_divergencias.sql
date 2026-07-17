-- Corrige RLS em almoxo_divergencias.
-- Sintoma: "new row violates row-level security policy for table
-- almoxo_divergencias" ao clicar em "Salvar Divergências no Sistema" na
-- Conferência SAP x PRAXIO (confSalvarDivergenciasAbertas) -- RLS está ligado
-- mas sem policy que libere INSERT/UPDATE pra usuário autenticado.
--
-- Mesmo padrão já aplicado em almoxo_inventario_turno
-- (scripts/fix_rls_almoxo_inventario_turno.sql) e usado em
-- almoxo_inventario_tratativas desde a criação. Idempotente, seguro rodar de novo.

ALTER TABLE almoxo_divergencias ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Autenticado pode tudo" ON almoxo_divergencias;
CREATE POLICY "Autenticado pode tudo"
  ON almoxo_divergencias FOR ALL TO authenticated
  USING (true) WITH CHECK (true);
