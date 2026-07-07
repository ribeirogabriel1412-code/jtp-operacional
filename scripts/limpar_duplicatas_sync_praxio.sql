-- Limpeza pontual (2026-07-07): o sync_solicitacoes_praxio.ps1 tinha um bug
-- de sintaxe no filtro in.() do PostgREST (aspas simples nao suportadas
-- nesse operador -- ja corrigido no script) que fazia a checagem de "ja
-- existe" sempre voltar vazia, duplicando os itens a cada execucao (5
-- rodadas = 5 copias de cada item). Nenhuma das linhas duplicadas foi
-- separada pelo Almox ainda (todas em status='solicitado_pcm'), entao e
-- seguro limpar mantendo so a mais antiga de cada grupo.

-- 1) CONFIRA antes de apagar -- mostra quantas linhas seriam removidas por OS
SELECT os_numero, cod_sap, COUNT(*) AS copias
FROM requisicoes_compra
WHERE criado_por = 'Sync PRAXIO'
GROUP BY os_numero, cod_sap
HAVING COUNT(*) > 1
ORDER BY copias DESC;

-- 2) Apaga as duplicatas, mantendo a linha mais antiga (criado_em) de cada
--    grupo (os_numero, cod_sap). So mexe em linhas do sync que ainda estao
--    'solicitado_pcm' -- nunca em linha ja separada/comprada/etc, mesmo que
--    por algum motivo futuro exista duplicata em outro status.
WITH duplicatas AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY os_numero, cod_sap
           ORDER BY criado_em ASC
         ) AS rn
  FROM requisicoes_compra
  WHERE criado_por = 'Sync PRAXIO'
    AND status = 'solicitado_pcm'
)
DELETE FROM requisicoes_compra
WHERE id IN (SELECT id FROM duplicatas WHERE rn > 1);

-- 3) Confere que nao sobrou duplicata
SELECT os_numero, cod_sap, COUNT(*) AS copias
FROM requisicoes_compra
WHERE criado_por = 'Sync PRAXIO'
GROUP BY os_numero, cod_sap
HAVING COUNT(*) > 1;
