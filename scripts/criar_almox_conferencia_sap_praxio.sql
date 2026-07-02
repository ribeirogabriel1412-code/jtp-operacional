-- Tabela: almox_conferencia_sap_praxio
-- Motor comparativo de saldo de estoque entre SAP e PRAXIO
-- Grava apenas os itens com desvio; atualizada a cada importação.

create table if not exists almox_conferencia_sap_praxio (
  id               uuid primary key default gen_random_uuid(),
  garagem_id       text not null,
  data_referencia  date not null,
  cod_sap          text not null,
  descricao        text,
  grupo            text,
  saldo_sap        numeric(12,3) default 0,
  saldo_praxio     numeric(12,3) default 0,
  diferenca        numeric(12,3) default 0,   -- saldo_sap - saldo_praxio
  preco_medio_sap  numeric(14,4) default 0,
  valor_sap        numeric(16,2) default 0,
  criado_em        timestamptz default now()
);

-- Índices
create index if not exists idx_conf_sap_praxio_garagem_data
  on almox_conferencia_sap_praxio(garagem_id, data_referencia);

create index if not exists idx_conf_sap_praxio_cod
  on almox_conferencia_sap_praxio(cod_sap);

-- RLS: acesso total para usuários autenticados (o motor roda no browser logado)
alter table almox_conferencia_sap_praxio enable row level security;

create policy "Acesso autenticado"
  on almox_conferencia_sap_praxio for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
