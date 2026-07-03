-- ── Checklist 3.3 — Ronda Operacional ───────────────────────────────────────
-- Rode este arquivo no Supabase SQL Editor para ativar o 3.3
-- Seguro re-executar (IF NOT EXISTS / OR REPLACE)

-- 1. Cria a tabela
CREATE TABLE IF NOT EXISTS checklist_33 (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  data            date NOT NULL,
  turno           text NOT NULL CHECK (turno IN ('dia','noite')),
  rodada          integer,
  dados           jsonb NOT NULL DEFAULT '{}'::jsonb,
  status          text NOT NULL DEFAULT 'em_andamento',
  preenchido_por  text,
  preenchido_em   timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- 2. Índices para as queries do app
CREATE INDEX IF NOT EXISTS checklist_33_garagem_data_turno
  ON checklist_33 (garagem_id, data, turno);

CREATE INDEX IF NOT EXISTS checklist_33_garagem_data_turno_rodada
  ON checklist_33 (garagem_id, data, turno, rodada);

-- 3. RLS — habilita e cria política para usuários autenticados
ALTER TABLE checklist_33 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Autenticado pode tudo" ON checklist_33;
CREATE POLICY "Autenticado pode tudo"
  ON checklist_33 FOR ALL
  USING  (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- ── Correção de instabilidade — 2026-07-03 ──────────────────────────────────
-- A tabela já existia antes (id int8, coluna criado_em) então o CREATE TABLE
-- acima nunca rodou de fato. O app fazia insert/update sem constraint única
-- em (garagem_id,data,turno,rodada) → duas pessoas abrindo o 3.3 ao mesmo
-- tempo podiam criar 2 registros pro mesmo dia/turno/rodada. Quando isso
-- acontece, o app quebra com "Base checklist_33 não encontrada" só pra
-- aquele dia/turno específico (o .maybeSingle() do app recusa 2+ linhas).

-- 4. Diagnóstico — RODE PRIMEIRO, é só leitura. Se vier vazio, não há duplicidade.
SELECT garagem_id, data, turno, rodada, count(*) AS qtd, array_agg(id ORDER BY criado_em) AS ids
FROM checklist_33
WHERE rodada IS NOT NULL
GROUP BY garagem_id, data, turno, rodada
HAVING count(*) > 1
ORDER BY data, turno, rodada;

-- 5. Limpeza — só rode se o diagnóstico acima retornou linhas.
-- Funde os dados (respostas/resumos/setores_concluidos) dos duplicados no
-- registro mais antigo do grupo, valor mais recente vence por item, depois
-- apaga os duplicados extras. Nada de outros dias/turnos é afetado.
WITH dups AS (
  SELECT garagem_id, data, turno, rodada, array_agg(id ORDER BY criado_em) AS ids
  FROM checklist_33
  WHERE rodada IS NOT NULL
  GROUP BY garagem_id, data, turno, rodada
  HAVING count(*) > 1
),
respostas_merge AS (
  SELECT d.ids[1] AS keep_id, jsonb_object_agg(kv.key, kv.value ORDER BY c.criado_em) AS respostas
  FROM dups d JOIN checklist_33 c ON c.id = ANY(d.ids)
  CROSS JOIN LATERAL jsonb_each(COALESCE(c.dados->'respostas','{}'::jsonb)) AS kv
  GROUP BY d.ids[1]
),
resumos_merge AS (
  SELECT d.ids[1] AS keep_id, jsonb_object_agg(kv.key, kv.value ORDER BY c.criado_em) AS resumos
  FROM dups d JOIN checklist_33 c ON c.id = ANY(d.ids)
  CROSS JOIN LATERAL jsonb_each(COALESCE(c.dados->'resumos','{}'::jsonb)) AS kv
  GROUP BY d.ids[1]
),
setores_merge AS (
  SELECT d.ids[1] AS keep_id, jsonb_object_agg(kv.key, kv.value ORDER BY c.criado_em) AS setores_concluidos
  FROM dups d JOIN checklist_33 c ON c.id = ANY(d.ids)
  CROSS JOIN LATERAL jsonb_each(COALESCE(c.dados->'setores_concluidos','{}'::jsonb)) AS kv
  GROUP BY d.ids[1]
)
UPDATE checklist_33 c
SET dados = jsonb_build_object(
      'respostas', COALESCE(rm.respostas,'{}'::jsonb),
      'resumos', COALESCE(sm.resumos,'{}'::jsonb),
      'setores_concluidos', COALESCE(scm.setores_concluidos,'{}'::jsonb)
    )
FROM respostas_merge rm
FULL JOIN resumos_merge sm ON sm.keep_id = rm.keep_id
FULL JOIN setores_merge scm ON scm.keep_id = COALESCE(rm.keep_id, sm.keep_id)
WHERE c.id = COALESCE(rm.keep_id, sm.keep_id, scm.keep_id);

DELETE FROM checklist_33
WHERE id IN (
  SELECT unnest(ids[2:]) FROM (
    SELECT array_agg(id ORDER BY criado_em) AS ids
    FROM checklist_33
    WHERE rodada IS NOT NULL
    GROUP BY garagem_id, data, turno, rodada
    HAVING count(*) > 1
  ) x
);

-- 6. Constraint única — impede duplicidade pra sempre (necessária pro upsert do app).
-- Precisa ser uma constraint COMPLETA (sem WHERE): o Postgres só usa índice
-- parcial em ON CONFLICT se o próprio INSERT repetir o mesmo WHERE, e o
-- upsert do app não faz isso. NULLs em `rodada` continuam sem conflitar entre si.
DROP INDEX IF EXISTS checklist_33_uniq;
CREATE UNIQUE INDEX checklist_33_uniq
  ON checklist_33 (garagem_id, data, turno, rodada);
