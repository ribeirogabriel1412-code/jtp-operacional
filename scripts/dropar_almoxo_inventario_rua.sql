-- Remove o processo descontinuado de "Inventário de Rua" do almoxarifado:
-- contagem por rua (almoxo_inventario_rua) e o cadastro que só existia pra
-- suportar esse processo (almoxo_ruas, almoxo_rua_responsavel).
--
-- almoxo_itens é MANTIDA (dados preservados) -- só perde a FK pra almoxo_ruas,
-- que é removida junto pelo CASCADE. A coluna rua_id em almoxo_itens continua
-- existindo, só fica sem referência (não é mais validada contra almoxo_ruas).
-- Nenhuma tela do app usa mais almoxo_itens no momento desta limpeza (2026-07-17).
--
-- CASCADE também remove a FK que almoxo_divergencias.rua_id tinha apontando
-- pra almoxo_ruas -- não apaga nenhuma linha de almoxo_divergencias, só a
-- constraint. Histórico de divergências com origem='rua' é preservado.

DROP TABLE IF EXISTS almoxo_inventario_rua CASCADE;
DROP TABLE IF EXISTS almoxo_rua_responsavel CASCADE;
DROP TABLE IF EXISTS almoxo_ruas CASCADE;
