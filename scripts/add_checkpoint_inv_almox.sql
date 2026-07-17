-- Adiciona o checkpoint "Conferência SAP x PRAXIO — Inventário Almoxarifado"
-- ao Painel de Supervisão.
--
-- Passa a aparecer no Quadro de Atividades e Envios sempre que o Líder de
-- Suprimentos clicar em "Salvar Divergências no Sistema" na aba SAP x PRAXIO
-- do Painel do Líder (index.html, confSalvarDivergenciasAbertas) -- inclusive
-- quando NÃO acha nenhum desvio (conferência limpa também é conformidade,
-- só não grava nada em almoxo_divergencias nesse caso).
--
-- Ajuste a coluna `hora` abaixo se o prazo real for outro -- 10:00 foi só um
-- valor razoável, não veio de nenhuma régua combinada.

INSERT INTO supervisao_checkpoints (id, documento, ferramenta, hora, responsavel_cargo, tipo, ordem) VALUES
  ('rinvalmox_1000', 'Conferência SAP x PRAXIO — Inventário Almoxarifado', 'App', '10:00', 'lider_suprimentos', 'inv_almox', 26)
ON CONFLICT (id) DO UPDATE SET
  documento=EXCLUDED.documento, ferramenta=EXCLUDED.ferramenta, hora=EXCLUDED.hora,
  responsavel_cargo=EXCLUDED.responsavel_cargo, tipo=EXCLUDED.tipo, ordem=EXCLUDED.ordem, ativo=true;
