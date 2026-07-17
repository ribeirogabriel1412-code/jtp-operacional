-- Campo de tratativa para Trocas e Dobras do Plantao, no mesmo padrao do
-- tratativa_pcm ja existente em plantao_sos (ver add_tratativa_pcm_plantao_sos.sql).
-- Usado no painel "Fechamento do Plantao" (Lider Operacional) pra registrar o
-- acompanhamento de cada troca/dobra direto no relatorio.
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar (IF NOT EXISTS).

ALTER TABLE plantao_trocas ADD COLUMN IF NOT EXISTS tratativa text;
ALTER TABLE plantao_trocas ADD COLUMN IF NOT EXISTS tratativa_por text;
ALTER TABLE plantao_trocas ADD COLUMN IF NOT EXISTS tratativa_em timestamptz;

ALTER TABLE plantao_dobras ADD COLUMN IF NOT EXISTS tratativa text;
ALTER TABLE plantao_dobras ADD COLUMN IF NOT EXISTS tratativa_por text;
ALTER TABLE plantao_dobras ADD COLUMN IF NOT EXISTS tratativa_em timestamptz;

-- RLS ja esta ligado nessas tabelas com policy "Autenticado pode tudo" (FOR ALL),
-- entao UPDATE dessas colunas novas ja funciona sem mudanca nenhuma de policy.
