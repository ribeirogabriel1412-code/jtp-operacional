-- Escalas do Instrutor pros Monitores (campo/linha/carro) --
-- Rode este arquivo no Supabase SQL Editor.
-- Alimentada pela aba "Viagens" do Painel do Instrutor (index.html,
-- _instrViagens) -- o instrutor olha o ranking de carros ruins, as linhas
-- mais prejudicadas e os motoristas mais frequentes nesses carros, e escala
-- direto pra um monitor (campo/linha/carro). Consumida pelas telas mobile do
-- monitor (app-mobile.html, telaMonitor*) pra saber o que cada um deve fazer
-- no dia.

CREATE TABLE IF NOT EXISTS instrutor_atribuicoes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  garagem_id      uuid NOT NULL,
  tipo            text NOT NULL,  -- 'motorista' | 'linha' | 'carro'
  data            date NOT NULL,
  motorista_cod   text,
  linha           text,
  veiculo         text,
  km_l            numeric,        -- km/l do carro no momento da escala (referencia)
  monitor_id      uuid NOT NULL,
  monitor_nome    text,
  atribuido_por   text,
  criado_em       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS instrutor_atribuicoes_monitor
  ON instrutor_atribuicoes (garagem_id, monitor_id, data);

CREATE INDEX IF NOT EXISTS instrutor_atribuicoes_garagem_data
  ON instrutor_atribuicoes (garagem_id, data);

-- Mesmo padrao de RLS das outras tabelas do Instrutor/Monitor (monitoria_registros
-- etc): exige sessao autenticada, sem policy por dono especifico (garagem
-- inteira compartilha o mesmo perfil de acesso dentro do app).
ALTER TABLE instrutor_atribuicoes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS instrutor_atribuicoes_all ON instrutor_atribuicoes;
CREATE POLICY instrutor_atribuicoes_all ON instrutor_atribuicoes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT ALL ON instrutor_atribuicoes TO authenticated;
