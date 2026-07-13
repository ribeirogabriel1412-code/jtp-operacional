-- ── Telemetria de viagens por veículo (Gool System / rastreador) ──
-- Rode este arquivo no Supabase SQL Editor.
-- Fonte: JSON mensal consolidado no SharePoint (pasta "TELEMETRIA/Consolidado"),
--        via scripts/sync_telemetria_viagens.ps1
-- Granularidade: 1 linha por viagem/evento de veículo (start_time -> end_time).
-- Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS telemetria_viagens (
  id                              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  competencia                     text NOT NULL,           -- "YYYY-MM", usado para delete+insert por mês
  prefixo                         text,                    -- ex: "02.190" (PREFIXO do JSON, já trimado)
  placa                           text,                    -- unit_label
  group_name                      text,
  subgroup_name                   text,
  device_id                       bigint,
  vehicle_id                      bigint,
  driver_name                     text,
  matricula                       text,
  cnh                             text,
  identifier                      text,
  -- Timestamps vêm sem timezone no JSON de origem (hora local do rastreador).
  -- Ver memória "project_timezones" antes de comparar entre garagens com fuso diferente.
  start_time                      timestamp NOT NULL,
  end_time                        timestamp,
  start_odometer                  numeric,
  end_odometer                    numeric,
  distance_traveled                numeric,
  fuel_used                       numeric,
  total_time                      numeric,   -- segundos
  time_over_speed                 numeric,
  time_cluth_excess               numeric,
  time_stopped                    numeric,
  time_moving                     numeric,
  time_engine_off                 numeric,
  time_blue                       numeric,
  time_eco_roll                   numeric,
  time_stop_engine_on_productive  numeric,
  time_low_speed                  numeric,
  time_green                      numeric,
  time_extra_eco                  numeric,
  time_yellow                     numeric,
  time_red                        numeric,
  time_stop_engine_on             numeric,
  time_stop_accel                 numeric,
  time_tolerancia                 numeric,
  time_inercia                    numeric,
  time_banguela                   numeric,
  updated_at                      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (device_id, start_time)
);

CREATE INDEX IF NOT EXISTS telemetria_viagens_competencia
  ON telemetria_viagens (competencia);
CREATE INDEX IF NOT EXISTS telemetria_viagens_prefixo
  ON telemetria_viagens (prefixo, start_time DESC);

-- Escrito por script PowerShell (chave anon, sem sessao autenticada) --
-- mesmo padrao do viagens_resumo/instrutor_kml_detalhado: desabilita RLS, concede a anon.
ALTER TABLE telemetria_viagens DISABLE ROW LEVEL SECURITY;
ALTER TABLE telemetria_viagens NO FORCE ROW LEVEL SECURITY;
GRANT ALL ON telemetria_viagens TO anon;
GRANT ALL ON telemetria_viagens TO authenticated;
