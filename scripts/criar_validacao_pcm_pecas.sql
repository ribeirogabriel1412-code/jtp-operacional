-- Checkbox de validacao do PCM na tela "Peças PRAXIO" (Painel PCM) -- o PCM
-- confere que a peça listada (vinda do sync do PRAXIO) realmente foi usada
-- na OS, sem mexer no fluxo de separar/entregar do Almox (que continua
-- baseado em status). Rode este arquivo no Supabase SQL Editor.

ALTER TABLE requisicoes_compra
  ADD COLUMN IF NOT EXISTS validado_pcm     boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS validado_pcm_por text,
  ADD COLUMN IF NOT EXISTS validado_pcm_em  timestamptz;
