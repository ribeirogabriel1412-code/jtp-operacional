-- Amplia os checklists do Monitor -- separa "condicao do carro" (mecanica,
-- sem relacao com quem dirige) de "conducao + motorista" (comportamento
-- durante a viagem acompanhada). Rode este arquivo no Supabase SQL Editor.

-- monitor_relatorio_carro: checklist item a item (freios/ar/portas/ruidos/
-- painel/limpeza/pneus), cada um 'ok' | 'atencao' | 'critico'. O campo
-- condicao_interna existente continua sendo gravado (calculado a partir do
-- pior item) pra nao quebrar as telas que ja leem ele (index.html
-- _instrRelatorios, _monFormRelCarro).
ALTER TABLE monitor_relatorio_carro
  ADD COLUMN IF NOT EXISTS chk_freios          text,
  ADD COLUMN IF NOT EXISTS chk_ar_condicionado text,
  ADD COLUMN IF NOT EXISTS chk_portas          text,
  ADD COLUMN IF NOT EXISTS chk_ruidos          text,
  ADD COLUMN IF NOT EXISTS chk_painel          text,
  ADD COLUMN IF NOT EXISTS chk_limpeza         text,
  ADD COLUMN IF NOT EXISTS chk_pneus           text;

-- monitoria_registros: infracoes novas -- conducao (marcha/ultrapassagem/
-- parada) e motorista (uniforme/cordialidade/avisos), complementando as 6
-- que ja existiam (velocidade/frenagem/aceleracao/celular/cinto/postura).
ALTER TABLE monitoria_registros
  ADD COLUMN IF NOT EXISTS inf_marcha        boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS inf_ultrapassagem boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS inf_parada        boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS inf_uniforme      boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS inf_cordialidade  boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS inf_avisos        boolean NOT NULL DEFAULT false;
