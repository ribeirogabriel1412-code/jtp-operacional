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

-- monitoria_registros: infracoes de conducao (marcha/ultrapassagem/parada),
-- complementando as 3 que ja existiam (velocidade/frenagem/aceleracao).
ALTER TABLE monitoria_registros
  ADD COLUMN IF NOT EXISTS inf_marcha        boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS inf_ultrapassagem boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS inf_parada        boolean NOT NULL DEFAULT false;

-- inf_uniforme/inf_cordialidade/inf_avisos (2026-07-07, tarde) foram
-- substituidos pelos indicadores de telemetria abaixo antes de irem pra
-- producao -- as colunas booleanas ficam de fora do INSERT (nunca chegaram a
-- ser usadas de verdade), sem necessidade de dropar nada.

-- Motorista: ao inves de checkbox sim/nao, o monitor agora avalia 4
-- indicadores do mesmo tipo que o sistema de telemetria da empresa ja usa
-- (marcha lenta, faixa verde, faixa amarela, inercia), cada um de 1 a 5
-- estrelas (5 = melhor). Fica lado a lado com a nota geral (1-10) que ja
-- existia.
ALTER TABLE monitoria_registros
  ADD COLUMN IF NOT EXISTS tel_marcha_lenta  smallint,
  ADD COLUMN IF NOT EXISTS tel_faixa_verde   smallint,
  ADD COLUMN IF NOT EXISTS tel_faixa_amarela smallint,
  ADD COLUMN IF NOT EXISTS tel_inercia       smallint;

-- monitor_relatorio_linha (2026-07-07): checklist da linha -- itens que dao
-- pra contar (semaforo, cruzamento) viram numero; o resto (tempo de
-- percurso, problema de via) vira uma lista de relatos livres que o monitor
-- vai adicionando durante o percurso, guardada como array json
-- ({tipo, texto}[]) -- nao precisa de tabela filha pra uma lista curta.
ALTER TABLE monitor_relatorio_linha
  ADD COLUMN IF NOT EXISTS semaforos_problema    integer,
  ADD COLUMN IF NOT EXISTS cruzamentos_perigosos integer,
  ADD COLUMN IF NOT EXISTS relatos               jsonb NOT NULL DEFAULT '[]'::jsonb;
