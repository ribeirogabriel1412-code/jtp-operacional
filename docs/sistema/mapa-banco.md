# Mapa de Tabelas — Supabase → App

> Gerado em 2026-07-17 a partir de grep em [index.html](../../index.html) e [app-mobile.html](../../app-mobile.html) (todas as chamadas `sb.from('...')`) cruzado com os scripts `CREATE TABLE` em `scripts/*.sql` e na raiz do repo.
>
> **Limitação importante**: este mapa reflete o que o *código* usa, não uma leitura ao vivo do banco. Para achar tabelas realmente órfãs (existem no Supabase mas nenhum código as referencia), compare esta lista com o Table Editor — eu não tenho acesso direto ao banco nesta sessão. O que consigo garantir com certeza é o oposto: **tabelas usadas no código que não têm script de criação versionado** (marcadas com ⚠️).

83 tabelas distintas referenciadas no código, organizadas por módulo.

---

## 1. Cadastro Base

| Tabela | Script de criação | Usada em |
|---|---|---|
| `frota` | `criar_banco_novo.sql` | index.html, app-mobile.html — cadastro de veículos, usado em quase todo módulo |
| `garagens` | `criar_banco_novo.sql` | index.html, app-mobile.html — unidades/filiais |
| `perfis` | `criar_banco_novo.sql` | index.html, app-mobile.html — usuários/login/cargo |

## 2. Operação Diária (Soltura / Oficina / OS)

| Tabela | Script | Usada em |
|---|---|---|
| `soltura_2_10` | `criar_banco_novo.sql` | soltura de frota (dia/noite) |
| `ocorrencias_22` | `criar_banco_novo.sql` | OS/ocorrências de manutenção — tabela central da oficina |
| `historico_22` | `criar_banco_novo.sql` | histórico de eventos da OS |
| `checklist_22` | `criar_banco_novo.sql` | checklist vinculado à OS |
| `checklist_liberacao` | `criar_banco_novo.sql` | liberação de veículo pela oficina |
| `checklist_37` | `criar_banco_novo.sql` | checklist (oficina) |
| `checklist_38` | `criar_banco_novo.sql` | checklist (oficina) |
| `os_hc` | ⚠️ **sem script** | referenciada em index.html:8088/8906 e app-mobile.html:1686/1902 — provável tabela de horas/HC de OS, criada direto no Studio |
| `acompanhamento_manutencao` | `scripts/criar_acompanhamento_manutencao.sql` | tela "Acompanhamento de Manutenção" (rodadas hora a hora) |
| `checklist_equipamentos` | `criar_banco_novo.sql` | checklist de equipamentos da oficina |
| `checklist_nok_pendentes` | `criar_banco_novo.sql` | pendências de itens reprovados em checklist |
| `checklist_lubrificacao` | ⚠️ **sem script** | referenciada em index.html:165/9271+ e app-mobile.html:5642/9271+ — sem CREATE TABLE versionado |

## 3. Lavagem

| Tabela | Script | Usada em |
|---|---|---|
| `checklist_lavagem` | `criar_banco_novo.sql` | checklist do processo de lavagem |
| `cronograma_lavagem` | `criar_banco_novo.sql` | agenda/cronograma |
| `fechamento_lavagem` | `criar_banco_novo.sql` | fechamento de turno da lavagem |
| `vistoria_lavagem` | `criar_banco_novo.sql` | vistoria pós-lavagem |

## 4. Abastecimento / Recolha / Avarias

| Tabela | Script | Usada em |
|---|---|---|
| `abastecimento_checklist` | `criar_banco_novo.sql` | checklist de abastecimento |
| `fechamento_abastecimento` | `criar_banco_novo.sql` | fechamento de turno do abastecimento |
| `recolha_checklist` | `criar_banco_novo.sql` | checklist de recolha de frota |
| `avarias_recolha` | `criar_banco_novo.sql` | avarias registradas na recolha |

## 5. Almoxarifado

| Tabela | Script | Usada em |
|---|---|---|
| ~~`almoxo_ruas`~~ | 🗑️ **descontinuada 2026-07-17** | cadastro de ruas; só existia pra suportar o processo de inventário por rua. Tela "WMS — Catálogo" (`renderAlmoxWMS`) removida do index.html (menu, rota `ferr-almox-wms` e função). Drop em `scripts/dropar_almoxo_inventario_rua.sql` |
| ~~`almoxo_rua_responsavel`~~ | 🗑️ **descontinuada 2026-07-17** | responsável (almoxarife) por rua — só existia pra saber quem contava cada rua. Removida junto com `almoxo_ruas` |
| `almoxo_itens` | ⚠️ **sem script** | catálogo de itens — **mantida por decisão explícita**, mas sem nenhuma tela do app usando (perdeu a única UI, que era dentro do WMS removido). Dados preservados no banco, órfã de FK com `almoxo_ruas` |
| ~~`almoxo_inventario_rua`~~ | 🗑️ **descontinuada 2026-07-17** | contagem "Inventário da Rua" removida do index.html; drop em `scripts/dropar_almoxo_inventario_rua.sql` |
| `almoxo_inventario_turno` | ⚠️ **sem script** | Inventário Rotativo — contagem física por almoxarife (self-check + conferência cega do turno seguinte); fonte real da dupla contagem, RLS reabilitado em `scripts/fix_rls_almoxo_inventario_turno.sql` |
| ~~`almoxo_inventario_t1`~~ | 🗑️ **nunca existiu no banco — removida do código em 2026-07-17** | tabela nunca foi criada no Supabase; a tela desktop "Inventário T-1" (`renderAlmoxInventario`) que apontava pra ela nunca gravou nada de verdade. Removida do index.html (tela, rota `ferr-almox-inv`, botão, permissões em `core/desktop-config.js`) e das referências mortas no Painel de Acurácia e no Cruzamento SAP × PRAXIO, que passaram a usar a dupla contagem real de `almoxo_inventario_turno` (mesmo `req_id`, dois `almoxarife_id` diferentes) |
| `almoxo_inventario_tratativas` | `scripts/criar_almoxo_inventario_tratativas.sql` | tratativas de divergência de inventário |
| `almoxo_divergencias` | ⚠️ **sem script** | divergências gerais do almoxarifado |
| `almoxo_quadro_turno` | ⚠️ **sem script** | quadro/escala de turno do almoxarifado |
| `almoxo_pedidos_compra` | ⚠️ **sem script** | pedidos de compra do almoxarifado |
| `almoxo_baixa_rotacao_contagem` | `scripts/create_baixa_rotacao.sql` | KPI de baixa rotação — contagem |
| `almoxo_baixa_rotacao_itens` | `scripts/create_baixa_rotacao.sql` | KPI de baixa rotação — itens |
| `almoxo_wms_enderecos` | `scripts/importar_wms_porto_velho.sql` | endereços WMS (Porto Velho) |
| `almox_conferencia_sap_praxio` | `scripts/criar_almox_conferencia_sap_praxio.sql` | conferência cruzada SAP × PRAXIO |
| ~~`almox_devolucoes`~~ | 🗑️ **descontinuada 2026-07-17** | processo de devolução de peças removido do index.html (`renderAlmoxDevolucao` + menu `ferr-almox-dev`). Drop em `scripts/dropar_almox_devolucoes.sql`. Obs.: fallback antigo do app criava essa tabela com RLS desligado + GRANT ALL pra anon — verificar se já foi rodado em produção |
| `divergencias_pecas_praxio` | `scripts/criar_divergencias_pecas.sql` | divergências de peças vindas do PRAXIO |

## 6. Portaria

| Tabela | Script | Usada em |
|---|---|---|
| `portaria_recebimento` | `scripts/criar_portaria_recebimento.sql` | recebimento na portaria (+ `add_conferencia_portaria_recebimento.sql`, `add_tratativa_portaria_recebimento.sql`) |

## 7. Plantão

| Tabela | Script | Usada em |
|---|---|---|
| `plantao_dobras` | `scripts/criar_plantao_dobras_absenteismo.sql` | dobras de plantão |
| `plantao_absenteismo` | `scripts/criar_plantao_dobras_absenteismo.sql` | absenteísmo |
| `plantao_sos` | `scripts/criar_plantao_sos.sql` | chamados SOS do plantão |
| `plantao_trocas` | `scripts/criar_plantao_trocas.sql` | trocas de plantão |

## 8. Monitoria / Instrutor

| Tabela | Script | Usada em |
|---|---|---|
| `instrutor_kml` | ⚠️ **sem script** | Km/L por instrutor |
| `instrutor_kml_detalhado` | `scripts/criar_instrutor_kml_detalhado.sql` | detalhamento Km/L |
| `instrutor_ranking` | ⚠️ **sem script** | ranking de instrutores |
| `instrutor_acoes` | `scripts/criar_instrutor_acoes.sql` | ações corretivas do instrutor |
| `instrutor_atribuicoes` | `scripts/criar_atribuicoes_instrutor.sql` (+ `add_justificativa_instrutor_atribuicoes.sql`) | atribuição instrutor↔motorista |
| `monitoria_registros` | ⚠️ **sem script** | registros de monitoria |
| `monitor_relatorio_linha` | ⚠️ **sem script** | relatório de monitoria por linha |
| `monitor_relatorio_carro` | ⚠️ **sem script** | relatório de monitoria por carro |
| `monitor_escala_semanal` | `scripts/criar_escala_semanal_monitor.sql` | escala semanal do monitor |

## 9. Preventiva

| Tabela | Script | Usada em |
|---|---|---|
| `preventiva_semanas` | `scripts/preventiva_historico.sql` | histórico de preventiva por semana |
| `preventiva_valetamento` | `scripts/preventiva_historico.sql` | valetamento |
| `preventiva_importacoes` | `scripts/preventiva_historico.sql` | log de importações |
| `programacao_preventiva` | `criar_banco_novo.sql` | programação/agenda |
| `mao_obra_preventiva` | `criar_banco_novo.sql` | mão de obra alocada |

## 10. PCM / Peças / Compras

| Tabela | Script | Usada em |
|---|---|---|
| `requisicoes_compra` | `criar_banco_novo.sql` | requisições de compra (módulo grande, muito usado) |
| `ordens_servico_pecas` | `criar_banco_novo.sql` | peças vinculadas a OS |
| `movimentacao_pneu` | `criar_banco_novo.sql` | movimentação de pneus |
| `movimentacoes_estoque` | `criar_banco_novo.sql` | movimentações de estoque geral |
| `estoque` | `criar_banco_novo.sql` | estoque geral |
| `sap_precos` | `criar_banco_novo.sql` | preços vindos do SAP |
| `pcm_orcamento` | `criar_banco_novo.sql` | orçamento PCM |
| `pcm_conferencias` | `criar_banco_novo.sql` | conferências PCM |

## 11. Sync Externo (PRAXIO / Azure)

| Tabela | Script | Usada em |
|---|---|---|
| `praxio_os` | `criar_banco_novo.sql` | OS espelhada do Oracle PRAXIO |
| `viagens_resumo` | ⚠️ **sem script no repo** (populada por `scripts/sync-viagens-azure.ps1`) | resumo de viagens |

## 12. Indicadores / KPI

| Tabela | Script | Usada em |
|---|---|---|
| `km_base` | `criar_banco_novo.sql` | base de cálculo Km/L |
| `cpk_anomalias` | `criar_banco_novo.sql` | anomalias de CPK (custo por km) |
| `previsibilidade_26` | `criar_banco_novo.sql` | previsibilidade de frota |
| `indicadores_tecnicos` | `criar_banco_novo.sql` | indicadores técnicos gerais |
| `posicionamento_patio` | `criar_banco_novo.sql` | posicionamento de frota no pátio |
| `supervisao_checkpoints` | `criar_supervisao_checkpoints.sql` | Painel de Supervisão |

## 13. Fechamentos / Relatórios

| Tabela | Script | Usada em |
|---|---|---|
| `fechamento_24` | `criar_banco_novo.sql` | fechamento de turno (oficina 24h) |
| `fech24_prev_turno` | `criar_banco_novo.sql` | previsão do próximo turno |
| `fechamento_turno_garagem` | `criar_banco_novo.sql` | fechamento por garagem |
| `fechamento_turno_pcm` | `criar_banco_novo.sql` | fechamento PCM |
| `fechamento_lider_pcm` | `criar_banco_novo.sql` | fechamento líder PCM |
| `fechamento_plantao` | `criar_fechamento_plantao.sql` | fechamento diário de plantão (`scripts/fechar_plantao_diario.ps1`) |
| `relatorios_gerados` | `criar_banco_novo.sql` | log de relatórios/PDFs gerados |
| `relatorio_sos_218` | `criar_banco_novo.sql` | relatório de SOS |

---

## Tabelas criadas mas sem uso encontrado no código

Existem via script mas **nenhuma chamada `.from(...)` foi encontrada** em index.html/app-mobile.html:

- `metas_kml_veiculo` (`scripts/criar_metas_kml.sql`) — provavelmente só usada por script de sync/motor, não pela UI
- `telemetria_viagens` (`scripts/criar_telemetria_viagens.sql`) — idem, alimentada por `scripts/sync_telemetria_viagens.ps1`

Essas duas **não são lixo** — são tabelas de apoio a motores/scripts PowerShell, não a telas do app. Não confundir com órfãs reais.

## Como achar órfãs de verdade

Para identificar tabelas que existem no Supabase mas não aparecem em lugar nenhum (nem código, nem script), a forma mais rápida é: no Table Editor, listar todos os nomes (schema `public`) e comparar com as 83 desta lista. Qualquer tabela fora das duas listas (código + scripts) é candidata real a limpeza — mas confirme com o time antes de dropar, pode ter sido criada para um teste ou POC recente.

## Tabelas com CREATE TABLE mas sem `.from()` no código nem lugar nesta lista

Nenhuma outra encontrada além das duas citadas acima — todas as demais tabelas com script de criação são referenciadas em algum lugar do código.
