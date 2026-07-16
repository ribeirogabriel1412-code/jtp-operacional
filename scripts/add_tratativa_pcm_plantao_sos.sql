-- Conecta o SOS/RA do Plantão (tabela plantao_sos) ao Painel PCM: o SOS
-- aberto pelo plantão passa a aparecer numa aba própria dentro do PCM
-- (index.html) pra manutenção registrar o entendimento dela. Não vira OS,
-- é só pra manter o histórico do lado da manutenção.
-- Rode este arquivo no Supabase SQL Editor. Seguro re-executar (IF NOT EXISTS).

ALTER TABLE plantao_sos
  ADD COLUMN IF NOT EXISTS tratativa_pcm      text,
  ADD COLUMN IF NOT EXISTS tratativa_pcm_por  text,
  ADD COLUMN IF NOT EXISTS tratativa_pcm_em   timestamptz;

-- RLS já liberado pra authenticated em scripts/criar_plantao_sos.sql
-- ("Autenticado pode tudo" cobre UPDATE também) — nada a fazer aqui.
