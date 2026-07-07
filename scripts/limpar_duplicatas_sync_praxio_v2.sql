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
