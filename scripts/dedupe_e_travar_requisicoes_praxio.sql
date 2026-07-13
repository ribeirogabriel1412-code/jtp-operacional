-- Corrige a duplicação do sync PRAXIO (scripts/sync_solicitacoes_praxio.ps1) --
-- O sync roda a cada 30min e, por uma falha na deduplicação em memória (nunca
-- enxergava o que ele mesmo já tinha inserido), vinha recriando as mesmas
-- linhas (os_numero, cod_sap) a cada execução desde 2026-07-06. Só no dia
-- 2026-07-13 isso gerou 1110 linhas em excesso em requisicoes_compra.
--
-- Rode este arquivo no Supabase SQL Editor UMA VEZ, o quanto antes -- o passo
-- 2 (índice único) é o que impede qualquer duplicação nova a partir de agora,
-- mesmo que o script PowerShell rode de novo antes de você trocar a versão
-- corrigida no servidor do Task Scheduler.

-- 1) Limpeza: por (os_numero, cod_sap), mantém 1 linha só -- prioriza a que já
--    avançou no fluxo do almoxarifado (separado/pedido_compra/comprado) em vez
--    da mais antiga, pra não jogar fora trabalho que já foi feito. Cancela
--    (nunca apaga) as demais.
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY os_numero, cod_sap
      ORDER BY
        CASE status
          WHEN 'comprado'       THEN 0
          WHEN 'separado'       THEN 1
          WHEN 'pedido_compra'  THEN 1
          WHEN 'aprovado'       THEN 2
          WHEN 'pendente'       THEN 3
          WHEN 'solicitado_pcm' THEN 4
          ELSE 5
        END,
        id ASC
    ) AS rn
  FROM requisicoes_compra
  WHERE os_numero IS NOT NULL
    AND cod_sap IS NOT NULL
    AND status <> 'cancelado'
)
UPDATE requisicoes_compra
SET status = 'cancelado'
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- 2) Trava no banco: nunca mais deixa existir 2 linhas ativas (ou canceladas,
--    tanto faz) com o mesmo (os_numero, cod_sap). Linhas com os_numero NULL
--    (valetamento manual, avarias) nunca colidem entre si -- NULL nunca é
--    igual a NULL numa constraint UNIQUE do Postgres.
ALTER TABLE requisicoes_compra
  DROP CONSTRAINT IF EXISTS requisicoes_compra_os_cod_unica;
ALTER TABLE requisicoes_compra
  ADD CONSTRAINT requisicoes_compra_os_cod_unica UNIQUE (os_numero, cod_sap);
