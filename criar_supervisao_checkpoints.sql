-- Fase E do redesenho do Painel de Supervisão.
-- Substitui o array fixo SUPERVISAO_ROTINA (index.html) por uma tabela editável.
-- Revisar e rodar manualmente no SQL Editor do Supabase — não é executado automaticamente.

CREATE TABLE IF NOT EXISTS supervisao_checkpoints (
  id text PRIMARY KEY,
  documento text NOT NULL,
  ferramenta text NOT NULL,
  hora time NOT NULL,
  responsavel_cargo text NOT NULL,
  tipo text NOT NULL,
  area text,
  rodada int,
  ativo boolean NOT NULL DEFAULT true,
  ordem int,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE supervisao_checkpoints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Autenticado pode tudo" ON supervisao_checkpoints
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 25 checkpoints da planilha Quadro.xlsx (versão final enviada por Daniel em 2026-07-15)
INSERT INTO supervisao_checkpoints (id, documento, ferramenta, hora, responsavel_cargo, tipo, area, rodada, ordem) VALUES
  ('r21_0700',            '2.1 - Fechamento de turno',              'App', '07:00', 'supervisor',          '2.1',           NULL,   NULL, 1),
  ('r24_0400',            '2.4 - Fechamento PCM',                   'App', '04:00', 'assistente_pcm',      '2.4',           NULL,   NULL, 2),
  ('r34_0400',            '3.4 - Relatório de ativos',              'App', '04:00', 'assistente_pcm',      '3.4',           NULL,   NULL, 3),
  ('r26_0400',            '2.6 - Custo do turno',                   'App', '04:00', 'lider_pcm',           '2.6',           NULL,   NULL, 4),
  ('r210_0730',           '2.10 - Relatório de soltura',             'App', '07:30', 'lider_patio',         '2.10',          NULL,   NULL, 5),
  ('rabast_0730',         'Abastecimento e Recolha',                 'App', '07:30', 'lider_patio',         'abastecimento', NULL,   NULL, 6),
  ('rlav_0730',           'Lavagem',                                  'App', '07:30', 'lider_patio',         'lavagem',       NULL,   NULL, 7),
  ('r212_pcm_1000',       '2.12/2.14 - Indicadores Técnicos',        'App', '10:00', 'lider_pcm',           '2.12',          'pcm',        NULL, 8),
  ('r212_operacao_1000',  '2.12/2.14 - Indicadores Técnicos',        'App', '10:00', 'lider_operacional',   '2.12',          'operacao',   NULL, 9),
  ('r212_suprimentos_1000','2.12/2.14 - Indicadores Técnicos',       'App', '10:00', 'lider_suprimentos',   '2.12',          'suprimentos',NULL, 10),
  ('r218_1000',           '2.18 S.O.S',                              'App', '10:00', 'assistente_pcm',      '2.18',          NULL,   NULL, 11),
  ('r33_1_coord_1000',    '3.3 - 1 (Ronda operacional)',              'App', '10:00', 'coordenador',         '3.3',           'todos',1,    12),
  ('r33_1_pcm_1000',      '3.3 - 1.1 (Ronda operacional)',            'App', '10:00', 'lider_pcm',           '3.3',           'pcm',  1,    13),
  ('r33_1_almox_1000',    '3.3 - 1.2 (Ronda operacional)',            'App', '10:00', 'lider_almoxarifado',  '3.3',           'almox',1,    14),
  ('r33_1_operacao_1000', '3.3 - 1.3 (Ronda operacional)',            'App', '10:00', 'lider_operacional',   '3.3',           'operacao',1, 15),
  ('r24_1200',            '2.4 - Fechamento PCM',                    'App', '12:00', 'assistente_pcm',      '2.4',           NULL,   NULL, 16),
  ('r34_1200',            '3.4 - Relatório de ativos',                'App', '12:00', 'assistente_pcm',      '3.4',           NULL,   NULL, 17),
  ('r41_1500',            '4.1 - 5W2H',                               'App', '15:00', 'coordenador',         '4.1',           NULL,   NULL, 18),
  ('r33_2_coord_1600',    '3.3 - 2 (Ronda operacional)',              'App', '16:00', 'coordenador',         '3.3',           'todos',2,    19),
  ('r33_2_pcm_1600',      '3.3 - 2.1 (Ronda operacional)',            'App', '16:00', 'lider_pcm',           '3.3',           'pcm',  2,    20),
  ('r33_2_almox_1600',    '3.3 - 2.2 (Ronda operacional)',            'App', '16:00', 'lider_almoxarifado',  '3.3',           'almox',2,    21),
  ('r33_2_operacao_1600', '3.3 - 2.3 (Ronda operacional)',            'App', '16:00', 'lider_operacional',   '3.3',           'operacao',2, 22),
  ('r26_1600',            '2.6 - Custo do turno',                    'App', '16:00', 'lider_pcm',           '2.6',           NULL,   NULL, 23),
  ('r24_2000',            '2.4 - Fechamento PCM',                    'App', '20:00', 'assistente_pcm',      '2.4',           NULL,   NULL, 24),
  ('r34_2000',            '3.4 - Relatório de ativos',                'App', '20:00', 'assistente_pcm',      '3.4',           NULL,   NULL, 25)
ON CONFLICT (id) DO UPDATE SET
  documento=EXCLUDED.documento, ferramenta=EXCLUDED.ferramenta, hora=EXCLUDED.hora,
  responsavel_cargo=EXCLUDED.responsavel_cargo, tipo=EXCLUDED.tipo, area=EXCLUDED.area,
  rodada=EXCLUDED.rodada, ordem=EXCLUDED.ordem, ativo=true;
