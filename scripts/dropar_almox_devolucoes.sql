-- Remove o processo descontinuado de "Devolução de Peças" do almoxarifado.
-- Tela renderAlmoxDevolucao() (+ helpers e menu 'ferr-almox-dev') removida do index.html.
--
-- Observação: a tabela nunca chegou a ser criada com um CREATE TABLE versionado.
-- O próprio app tinha um fallback que, se a tabela não existisse, mostrava esse
-- SQL na tela pra alguém colar no Supabase -- e esse SQL desligava RLS e dava
-- GRANT ALL pra anon. Se a tabela já existe no banco, ela pode estar exposta
-- (leitura/escrita sem autenticação). Rode este DROP para eliminá-la de vez.

DROP TABLE IF EXISTS almox_devolucoes CASCADE;
