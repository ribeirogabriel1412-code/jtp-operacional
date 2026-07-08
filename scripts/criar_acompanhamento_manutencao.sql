-- ── Acompanhamento de Manutenção de Veículos (hora a hora) ──────────────────
-- Digitaliza o relatório em papel "GRUPO JTP | OPERAÇÃO GARAGEM — Acompanhamento
-- de Manutenção de Veículos": a cada rodada (~1h), o líder de oficina registra
-- etapa atual, evolução, problema, ação imediata e previsão de liberação de
-- cada OS em andamento. Rode este arquivo no Supabase SQL Editor.
-- Seguro re-executar (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS acompanhamento_manutencao (
  id              bigserial PRIMARY KEY,
  ocorrencia_id   bigint REFERENCES ocorrencias_22(id),
  garagem_id      uuid REFERENCES garagens(id),
  turno           text NOT NULL CHECK (turno IN ('dia','noite')),
  data_turno      date NOT NULL,
  rodada          integer NOT NULL,
  hora_registro   timestamptz NOT NULL DEFAULT now(),
  prefixo         text,
  numero_os       text,
  tipo_os         text,
  etapa_atual     text,
  evolucao        text,
  problema        text,
  acao_imediata   text,
  prev_liberacao  text,
  fechamento      boolean DEFAULT false,
  status_final    text,
  pendencias      text,
  criado_por      text,
  criado_em       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS acomp_manut_ocorrencia
  ON acompanhamento_manutencao (ocorrencia_id);

CREATE INDEX IF NOT EXISTS acomp_manut_turno
  ON acompanhamento_manutencao (garagem_id, data_turno, turno);

ALTER TABLE acompanhamento_manutencao ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Autenticado pode tudo" ON acompanhamento_manutencao;
CREATE POLICY "Autenticado pode tudo"
  ON acompanhamento_manutencao FOR ALL
  USING  (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');
