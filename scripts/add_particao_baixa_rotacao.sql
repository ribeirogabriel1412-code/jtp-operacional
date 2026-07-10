-- Divide o catálogo de baixa rotação em partições fixas por turno (Quadro de
-- Turnos do almoxarifado) -- cada turno cicla só dentro da sua partição, em
-- vez de todo mundo pescar do mesmo balaio. Rodar uma vez no SQL Editor.

ALTER TABLE almoxo_baixa_rotacao_itens
  ADD COLUMN IF NOT EXISTS particao smallint NOT NULL DEFAULT 0;

ALTER TABLE almoxo_baixa_rotacao_contagem
  ADD COLUMN IF NOT EXISTS particao smallint;

CREATE INDEX IF NOT EXISTS idx_baixa_rotacao_itens_garagem_particao
  ON almoxo_baixa_rotacao_itens(garagem_id, particao);
CREATE INDEX IF NOT EXISTS idx_baixa_rotacao_contagem_garagem_particao_ciclo
  ON almoxo_baixa_rotacao_contagem(garagem_id, particao, ciclo);
