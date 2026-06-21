# Mapa do Banco de Dados — JTP App
**Última atualização:** 2026-06-05

---

## Como ler este arquivo
- **Crítica** = app para sem ela
- **Importante** = funcionalidade principal depende dela
- **Suporte** = complementar, registro/auditoria

---

## GRUPO 1 — Frota e Operação Diária

| Tabela | Para que serve | Quem usa | Criticidade |
|--------|---------------|----------|-------------|
| `frota` | Cadastro dos veículos (prefixo, modelo, status) | Desktop + Mobile | Crítica |
| `soltura_2_10` | Escala de saída dos ônibus por turno e linha | Desktop + Mobile | Crítica |
| `garagens` | Cadastro das garagens | Desktop + Mobile | Crítica |
| `perfis` | Usuários, cargos e permissões | Desktop + Mobile | Crítica |

---

## GRUPO 2 — Lavagem

| Tabela | Para que serve | Quem usa | Criticidade |
|--------|---------------|----------|-------------|
| `checklist_lavagem` | Registro de lavagem por veículo/dia | Desktop + Mobile | Crítica |
| `vistoria_lavagem` | Aprovação/rejeição da lavagem pelo líder | Mobile | Importante |
| `fechamento_lavagem` | Fechamento ao fim do turno de lavagem | Mobile | Importante |

---

## GRUPO 3 — Manutenção / PCM (Ferramenta 2.2)

| Tabela | Para que serve | Quem usa | Criticidade |
|--------|---------------|----------|-------------|
| `ocorrencias_22` | **Tabela principal das OS** — estado atual de cada ocorrência | Desktop + Mobile | Crítica |
| `historico_22` | **Audit trail** — registra cada mudança de status na OS (quem, quando, o quê) | Desktop | Importante |
| `checklist_liberacao` | Itens que precisam ser verificados para liberar um veículo da oficina | Desktop + Mobile | Crítica |
| `ordens_servico_pecas` | Peças vinculadas a cada OS | Desktop | Importante |
| `estoque` | Estoque atual de peças no almoxarifado | Desktop | Importante |
| `movimentacoes_estoque` | **Audit trail** — registra cada saída de peça do estoque (qual OS consumiu) | Desktop | Suporte |
| `sap_precos` | Tabela de preços de peças (importada do SAP) | Desktop | Importante |
| `requisicoes_compra` | Pedidos de compra de peças ainda não disponíveis no estoque | Desktop + Mobile | Importante |
| `movimentacao_pneu` | Controle de troca e vida útil de pneus | Desktop | Suporte |

---

## GRUPO 4 — Abastecimento (Ferramenta 2.3)

| Tabela | Para que serve | Quem usa | Criticidade |
|--------|---------------|----------|-------------|
| `abastecimento_checklist` | Registro de cada abastecimento (veículo, litros, ARLA, km) | Desktop + Mobile | Crítica |
| `fechamento_abastecimento` | Fechamento do turno de abastecimento | Desktop + Mobile | Importante |

---

## GRUPO 5 — Preventiva (Ferramenta 2.6 / PCM)

| Tabela | Para que serve | Quem usa | Criticidade |
|--------|---------------|----------|-------------|
| `previsibilidade_26` | Agenda de manutenções preventivas (quando cada veículo deve passar pela revisão) | Desktop + Mobile | Importante |
| `programacao_preventiva` | Programação de manutenções preventivas pelo PCM | Mobile | Importante |
| `pcm_orcamento` | Orçamento disponível para o PCM (saldo por garagem/mês) | Desktop | Importante |
| `pcm_conferencias` | **Snapshots** de orçamento ao longo do dia (quanto gastou em cada momento) | Desktop | Suporte |

---

## GRUPO 6 — Checklists Operacionais

| Tabela | Para que serve | Quem usa | Criticidade |
|--------|---------------|----------|-------------|
| `checklist_22` | Checklist do procedimento 2.2 (manutenção) | Desktop | Importante |
| `checklist_33` | Checklist do procedimento 3.3 (ronda operacional) | Desktop + Mobile | Importante |
| `checklist_37` | Checklist do procedimento 3.7 | Desktop | Importante |
| `checklist_38` | Checklist do procedimento 3.8 | Desktop + Mobile | Importante |
| `checklist_equipamentos` | Checklist de equipamentos de segurança/operação | Desktop + Mobile | Suporte |
| `checklist_nok_pendentes` | Itens com problema (NOK) que ainda estão pendentes de correção | Mobile | Importante |

---

## GRUPO 7 — Recolha

| Tabela | Para que serve | Quem usa | Criticidade |
|--------|---------------|----------|-------------|
| `recolha_checklist` | Checklist de chegada dos veículos à garagem | Desktop + Mobile | Crítica |
| `posicionamento_patio` | Onde cada veículo está estacionado no pátio (zona/vaga) | Mobile | Importante |

---

## GRUPO 8 — Fechamentos de Turno

> **Cada fechamento é de uma área diferente. Nenhum é duplicado.**

| Tabela | Área | Ferramenta | Quem preenche |
|--------|------|------------|---------------|
| `fechamento_turno_garagem` | Fechamento geral da garagem por setor (op, man, sup) | 2.1 | Supervisor/Coordenador |
| `fechamento_turno_pcm` | Resumo operacional do PCM (frota liberada vs. parada) | 2.2 | Líder PCM |
| `fechamento_lider_pcm` | Fechamento financeiro do PCM (custo real vs. previsto) | 2.6 | Líder PCM |
| `fechamento_24` | Fechamento completo do turno 2.4 com resumo financeiro e de OS | 2.4 | Líder PCM |
| `fech24_prev_turno` | Quais preventivas foram incluídas no fechamento 2.4 | 2.4 | Líder PCM (automático) |
| `fechamento_abastecimento` | Fechamento do turno de abastecimento | 2.3 | Frentista/Líder |
| `fechamento_lavagem` | Fechamento do turno de lavagem | Lavagem | Líder Pátio |

---

## GRUPO 9 — Relatórios e Histórico

| Tabela | Para que serve | Quem usa | Criticidade |
|--------|---------------|----------|-------------|
| `relatorios_gerados` | Log de todos os relatórios gerados (quem, quando, tipo) | Desktop + Mobile | Suporte |
| `relatorio_sos_218` | Relatório do procedimento SOS 2.18 | Mobile | Suporte |

---

## Resumo — Tabelas por criticidade

### Críticas (app para sem elas)
`frota`, `soltura_2_10`, `garagens`, `perfis`, `ocorrencias_22`, `checklist_lavagem`, `abastecimento_checklist`, `checklist_liberacao`, `recolha_checklist`

### Importantes (funcionalidade principal)
`historico_22`, `requisicoes_compra`, `ordens_servico_pecas`, `estoque`, `sap_precos`, `previsibilidade_26`, `programacao_preventiva`, `checklist_33`, `checklist_38`, `fechamento_turno_garagem`, `fechamento_turno_pcm`, `fechamento_lavagem`, `fechamento_abastecimento`, `vistoria_lavagem`, `posicionamento_patio`, `checklist_nok_pendentes`, `pcm_orcamento`, `fechamento_lider_pcm`, `fechamento_24`

### Suporte (registro/auditoria)
`movimentacoes_estoque`, `movimentacao_pneu`, `pcm_conferencias`, `fech24_prev_turno`, `relatorios_gerados`, `relatorio_sos_218`, `checklist_equipamentos`, `checklist_22`, `checklist_37`

---

## O que NÃO é duplicado (mas parece ser)

| Par confuso | Explicação |
|---|---|
| `fechamento_24` + `fech24_prev_turno` | São complementares: um guarda o resumo do turno, o outro guarda quais preventivas foram incluídas naquele turno |
| `ocorrencias_22` + `historico_22` | São complementares: um guarda o estado atual da OS, o outro guarda o histórico de mudanças |
| `estoque` + `movimentacoes_estoque` | São complementares: um guarda o saldo atual, o outro registra cada entrada/saída |
| `checklist_lavagem` + `vistoria_lavagem` | São complementares: um é quem executa a lavagem, o outro é quem aprova |

---

## Sugestão de padrão para novas tabelas

Ao criar novas tabelas no futuro, use este padrão de nomenclatura:

- **Cadastros:** substantivo no plural → `veiculos`, `garagens`, `perfis`
- **Registros operacionais:** `area_acao` → `recolha_checklist`, `abastecimento_registro`
- **Fechamentos:** `fechamento_area` → `fechamento_lavagem`, `fechamento_abastecimento`
- **Histórico/Audit:** `historico_area` → `historico_22`, `movimentacoes_estoque`
- **Evite:** números soltos no nome (ex: `fech24_prev_turno`) → prefira `fechamento_24_preventivas`
