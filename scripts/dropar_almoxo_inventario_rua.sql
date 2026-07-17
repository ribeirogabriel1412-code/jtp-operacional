-- Remove o recurso descontinuado "Inventário da Rua" (contagem SAP x Físico por rua).
-- Mantém intacto o cadastro WMS (almoxo_ruas, almoxo_rua_responsavel, almoxo_itens),
-- que continua em uso pelo catálogo por rua.
--
-- CASCADE aqui só remove a constraint de FK que almoxo_divergencias.rua_id tinha
-- apontando pra almoxo_inventario_rua (se existir) -- não apaga nenhuma linha
-- de almoxo_divergencias. Histórico de divergências com origem='rua' é preservado.

DROP TABLE IF EXISTS almoxo_inventario_rua CASCADE;
