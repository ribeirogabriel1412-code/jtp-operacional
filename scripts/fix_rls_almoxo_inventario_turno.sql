-- Reabilita RLS em almoxo_inventario_turno.
-- A tabela guarda a contagem física do Inventário Rotativo (T-1 + Turno Atual)
-- lançada pelo almoxarife logado no app mobile -- hoje está com RLS desligado
-- (exposta a leitura/escrita sem autenticação via anon key).
--
-- O script scripts/fix_inventario_rotativo.sql (02/07) já continha esse mesmo
-- fix, mas o RLS voltou a aparecer desligado no Table Editor -- rode este de
-- novo pra garantir. É idempotente (seguro rodar mais de uma vez).

ALTER TABLE almoxo_inventario_turno ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Almox autenticado" ON almoxo_inventario_turno;
CREATE POLICY "Almox autenticado"
  ON almoxo_inventario_turno FOR ALL
  USING  (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');
