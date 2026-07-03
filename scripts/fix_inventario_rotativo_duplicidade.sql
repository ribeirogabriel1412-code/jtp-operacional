-- ── Fix Inventário Rotativo — duplicidade de contagem — 2026-07-03 ──────────
-- Cada almoxarife só pode ter UMA contagem por item (req_id). Sem essa
-- constraint, se o app não percebia que já existia registro (cache
-- desatualizado / duplo clique), criava outra linha do zero em vez de
-- atualizar a existente. Rode este arquivo no Supabase SQL Editor.

-- 1. Diagnóstico — RODE PRIMEIRO, é só leitura. Mostra os duplicados atuais.
SELECT req_id, almoxarife_id, almoxarife_nome, count(*) AS qtd, array_agg(id) AS ids
FROM almoxo_inventario_turno
WHERE req_id IS NOT NULL
GROUP BY req_id, almoxarife_id, almoxarife_nome
HAVING count(*) > 1;

-- 2. Limpeza — apaga os duplicados, mantendo sempre o registro de menor id
--    (os valores contados são idênticos entre os duplicados, então não há
--    dado divergente a fundir, só remover a repetição).
DELETE FROM almoxo_inventario_turno a
USING almoxo_inventario_turno b
WHERE a.req_id = b.req_id
  AND a.almoxarife_id = b.almoxarife_id
  AND a.req_id IS NOT NULL
  AND a.id > b.id;

-- 3. Constraint única — impede duplicidade pra sempre (necessária pro upsert do app).
-- Precisa ser COMPLETA (sem WHERE), senão o Postgres não usa ela no ON CONFLICT.
CREATE UNIQUE INDEX IF NOT EXISTS almoxo_inventario_turno_req_almox_uniq
  ON almoxo_inventario_turno (req_id, almoxarife_id);
