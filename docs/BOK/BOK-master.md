# BOK 1 — Corpo do Conhecimento Operacional — Grupo JTP
> **Versão viva** — mantida pelo agente `/jtp-bok`. Não editar manualmente.
> Documento original: `docs/BOK/Base/BOK_1.docx`
> Última atualização automática: 22/06/2026

---

## Sumário

1. [Hierarquia e Organograma](#1-hierarquia-e-organograma)
2. [Papéis e Responsabilidades](#2-papéis-e-responsabilidades)
3. [Gestão da Rotina](#3-gestão-da-rotina)
4. [Execução — Ferramentas, Cadeia de Ajuda e Protocolo de Nemoto](#4-execução)
5. [Diretrizes Corporativas](#5-diretrizes-corporativas)
6. [Changelog — Histórico de Atualizações](#6-changelog)

---

## 1. Hierarquia e Organograma

O **Coordenador de Garagem** é o responsável integral da operação (turno diurno). O **Supervisor de Garagem** atua em período noturno, em regime de corresponsabilidade.

### Camada de liderança (abaixo do Coordenador/Supervisor)
- Líder de PCM
- Líder de Suprimentos
- Líder Operacional (Escalante)
- Líder de Pátio
- Líder de Oficina *(garagens com +80 veículos: Líder Mecânica, Líder Elétrica, Líder Funilaria, Líder Borracharia)*
- Analista Administrativo
- Instrutor Operacional

### Base operacional
Manutenções, Almoxarifes, Assistentes de PCM, Plantão, Sinistros, Motoristas, Monitores Operacionais, Segurança do Trabalho.

> **NOTA:** Garagens com até 80 veículos → figura do Líder de Oficina. Garagens com +80 veículos → líderes de subáreas.

---

## 2. Papéis e Responsabilidades

### Coordenador de Garagem
- **Horário:** 08:00 ~ 18:00
- **Superior:** N3 Operações
- **Equipe:** Supervisor, Líder PCM, Líder Almoxarifado, Líder Operações, G&G Local
- **Missão:** Orquestrar manutenção, operação e áreas administrativas para disponibilidade máxima da frota com menor custo.
- **Indicadores-chave:** CPK, MKBF, gestão de suprimentos, absenteísmo/horas extras
- **Atribuições principais:**
  - Monitorar KPIs diários (soltura, pontualidade, limpeza, combustível, manutenção, suprimentos, pessoas)
  - Controle orçamentário diário (guincho, peças, combustível, lubrificantes, pneus, serviços)
  - Liderar Drumbeat Operacional + Gemba Walk
  - Interface com Poder Concedente
  - Gestão de pessoas da equipe completa

---

### Supervisor de Garagem
- **Horário:** 20:00 ~ 04:20 (Dom ~ Sex)
- **Superior:** Coordenador de Garagem
- **Equipe:** Líder PCM, Líder de Pátio, Almoxarifes, Embarcados
- **Missão:** Elo garantidor da disponibilidade máxima da frota e confiabilidade operacional noturna.
- **Indicadores-chave:** Soltura de frota (pontualidade), conformidade limpeza/conservação, preventivas noturnas
- **Atribuições principais:**
  - Monitorar desvios em tempo real (soltura, pontualidade, limpeza)
  - Gemba Walk nas frentes de pátio (abastecimento, manobra, lavagem)
  - Auditar Almoxarifado, PCM e Oficina na madrugada
  - Validar peças trocadas (foco itens > R$ 200)
  - Passagem de bastão com líderes (PCM, Almox, Operação)
  - Priorização estratégica da manutenção (tabelas paradas, custos)

---

### Líder PCM (Planejamento e Controle de Manutenção)
- **Horário:** Turno A 08:00 ~ 18:00 (5x2) | Turno B 20:00 ~ 04:20 (6x1)
- **Superior:** Coordenador / Supervisor
- **Equipe:** Analistas, Assistentes de PCM, Líder de Oficina
- **Missão:** Cérebro estratégico da manutenção — dados em planos de ação para maximizar previsibilidade e minimizar custos.
- **Indicadores-chave:** CPK, Cumprimento Preventiva, ciclo de vida pneus, MKBF
- **Atribuições:**
  - Garantir cumprimento do planejamento preventivo (kits + validação com almoxarifado)
  - Supervisionar solicitação de peças (preventiva e corretiva)
  - Distribuir demandas e definir prioridades de liberação de veículos
  - Garantir acuracidade no PRAXIO (abertura/fechamento OS, serviços pendentes)
  - Gestão de pessoas da equipe de manutenção

---

### Líder de Oficina (Manutentores / Mecânico A)
- **Horário:** Turno A 08:00 ~ 16:20 (6x1) | Turno B 20:00 ~ 04:20 (6x1)
- **Superior:** Líder de PCM
- **Equipe:** Mecânicos, Eletricistas, Borracheiros, Funileiros, Auxiliares
- **Missão:** Integridade técnica e confiabilidade dos veículos.
- **Atribuições:**
  - Controle de qualidade das OS (preventivas e corretivas)
  - Diagnóstico técnico e liberação de veículos
  - Distribuição e priorização de demandas para a equipe
  - Ponto focal técnico para recolhas anormais, SOS e intercorrências
  - Aprovação técnica de requisições de peças de alto valor

---

### Assistente de PCM
- **Horário:** Turno A 08:00 ~ 16:20 (6x1) | Turno B 20:00 ~ 04:20 (6x1)
- **Superior:** Líder de PCM
- **Telas mobile:** `oficina` (OS) + `checklist_equip` (3.4) + `sos218` (2.18) + `prev26` (2.6)
- **Missão:** Garantir rastreabilidade técnica das OS no PRAXIO e suporte operacional ao Líder PCM.
- **Atribuições:**
  - Abertura e fechamento de OS no PRAXIO (nunca pelo app — sistema de referência)
  - Controle de KM/hodômetro e consistência de dados no sistema
  - Acompanhar OS abertas sem baixa > 24h e acionar Líder PCM
  - Executar checklist de equipamentos de segurança (ferramenta 3.4)
  - Registrar e acompanhar SOS (ferramenta 2.18)
  - Apoiar previsibilidade de custo (ferramenta 2.6)
  - Garantir conformidade RJNP (relatório de irregularidades)

---

### Líder de Suprimentos
- **Horário:** 07:00 ~ 17:00 (5x2)
- **Superior:** Líder de Garagem (linha funcional: Supply Chain)
- **Equipe:** Almoxarifes e Auxiliares
- **Missão:** Acuracidade do estoque e fluxo contínuo de suprimentos — zero indisponibilidade por falta de peças.
- **Atribuições:**
  - Inventários rotativos diários/semanais (divergência zero)
  - Validar recebimento de materiais e combustível (Diesel) contra POs e NFs
  - Garantir baixas do dia
  - Gestão de RECON (peças para recuperação)
  - Planejamento semanal de compras (mínimo/máximo)
  - Preparação dos cestos de preventiva
  - WMS e 5S no almoxarifado
  - **Configurar Quadro de Turnos dos Almoxarifes** no Painel do Líder (desktop) — define horário de entrada e saída de cada almoxarife; dado usado pelo app mobile para calcular T-1 na Conferência de Turno
  - Gestão de pessoas do almoxarifado

---

### Almoxarife
- **Horário:** Conforme escala (turnos rotativos — Quadro de Turnos configurado pelo Líder de Suprimentos)
- **Superior:** Líder de Suprimentos
- **Tela mobile:** `valet_almox` (4 abas)
- **Tabelas Supabase:** `requisicoes_compra`, `almoxo_quadro_turno`
- **Missão:** Garantir disponibilidade de peças e materiais, atender solicitações do PCM com agilidade e manter acuracidade do estoque.
- **Atribuições:**
  - Preparar cestos de preventiva (Kits) conforme programação semanal
  - Atender solicitações de peças oriundas de OS (aba Solicitações)
  - Confirmar e registrar o que foi efetivamente entregue (com ou sem substituição de item)
  - Conferir movimentações do turno anterior e atual (aba Conferência)
  - Executar inventário da rua sob sua responsabilidade (aba Inv. Rua)
  - Receber e conferir materiais contra NF e PO
  - Comunicar divergências ao Líder de Suprimentos imediatamente

**Rotina no app — 4 abas do `valet_almox`:**

| Aba | Quando usar | O que faz |
|-----|-------------|-----------|
| **Kits** | Início do turno / tarde | Cestos de preventiva por data; verificar separação por veículo |
| **Solicitações** | Ao receber pedido do PCM | Ver itens solicitados via OS; confirmar entrega registrando item real + código SAP |
| **Conferência** | Virada de turno | Ver T-1 (turno anterior) e Turno Atual — só itens entregues — para passagem de bastão |
| **Inv. Rua** | Conforme escala de inventário | Contar itens físicos na rua atribuída e registrar no app |

**Gatilho de escalada:** Item entregue diferente do pedido → registrar na confirmação + comunicar Líder PCM. Falta de item em estoque → acionar Líder de Suprimentos para pedido de compra emergencial.

---

### Líder de Pátio
- **Horário:** 22:00 ~ 07:20 (6x1)
- **Superior:** Supervisor / Coordenador
- **Equipe:** Manobristas, Frentistas, Vistoriadores, Lavadores
- **Missão:** Organização, fluidez e confiabilidade da operação no pátio.
- **Atribuições:**
  - Coordenar disposição da frota conforme programação de saída
  - Gerir manobristas (prioridades, integridade veicular, normas de segurança)
  - Monitorar primeiras partidas + gestão de veículos "coringa"
  - Validador final de higiene e estética dos veículos antes da liberação
  - Acompanhar Realizado vs. Planejado das lavagens
  - Checklist de entrada: registrar avarias, falhas mecânicas ou sinistros
  - Supervisionar checklist de saída (itens de segurança)
  - Transformar dados dos checklists em OS ou ações de manutenção

---

### Líder Operacional (Escalante)
- **Horário:** 07:00 ~ 17:00 (5x2)
- **Superior:** Coordenador / Supervisor
- **Equipe:** Plantão, Sinistro, Motoristas
- **Missão:** Viabilizar operação diária — alocação eficiente de motoristas e veículos, 100% das viagens planejadas.
- **Atribuições:**
  - Escala estratégica para preventiva (sem prejudicar a operação)
  - Gestão de escalas (legislação + acordos sindicais)
  - Controle e tratativa de sinistros (SLA, RH, Seguradora)
  - Mitigação de atrasos e desvios em tempo real

---

### Lubrificador
- **Horário:** Turno noturno (junto com o pátio)
- **Superior:** Líder de Pátio / Supervisor de Garagem
- **Telas mobile:** `lubrificacao` + `lubri_rel`
- **Tabela Supabase:** `checklist_lubrificacao`
- **Missão:** Executar a lubrificação sistemática de toda a frota seguindo o plano de rotação semanal, garantindo 100% de cobertura antes da soltura.

**Lógica de rotação:**
- **Frota VW** (Volkswagen/Volksbus): lubrificada **todos os dias**
- **Demais veículos**: divididos em **5 grupos** rotacionados de Seg a Sex
- **Fim de semana**: pendências da semana que não foram executadas

**Rotina no app:**

| Momento | Ação | Resultado |
|---------|------|-----------|
| Início do turno | Abre tela `lubrificacao` | Vê lista de hoje: VW + grupo do dia |
| Para cada veículo | Toca no card do prefixo | Abre confirmação de execução |
| Após executar | Marca ✅ | Registra em `checklist_lubrificacao` |
| Veículo extra | Botão `+` no topo | Registra fora da rotina |
| Fim do turno | Aba `Semana` | Verifica pendências e % de cobertura |

**Gatilho de escalada:** Produto em falta → Líder Almoxarifado. Defeito no sistema → Líder Oficina. % < 100% ao fechar → registrar no fechamento e comunicar ao Supervisor.

---

### Membros da Ponta

#### Lavador
- **Horário:** Turno noturno (22:00 ~ 06:00 aprox.)
- **Superior:** Líder de Pátio
- **Tela mobile:** `lavagem` | **Tabela:** `checklist_lavagem`

| Momento | Ação | Resultado |
|---------|------|-----------|
| Início do turno | Abre tela `lavagem` | Vê lista: Pesada / Média / Leve |
| Para cada veículo | Toca no card | Abre checklist de lavagem |
| Executa lavagem | Preenche e confirma | Status → `executado` |
| Lavagem pesada | Acessa `lav_pesada` | Gestão específica preventiva |

**Gatilho:** Meta < 80% do planejado → acionar Líder de Pátio imediatamente.

---

#### Manobrista
- **Horário:** Turno noturno / madrugada
- **Superior:** Líder de Pátio
- **Tela mobile:** `patio_man` | **Tabela:** `posicionamento_patio`

| Momento | Ação | Resultado |
|---------|------|-----------|
| Início do turno | Abre tela `patio_man` | Vê mapa do pátio por zona |
| Ao posicionar veículo | Seleciona zona e registra | Salva prefixo + zona + vaga |
| Verificação | Toca na zona | Vê veículos e quem registrou |

**Gatilho:** Vaga crítica bloqueada por veículo "morto" → acionar Líder de Pátio.

---

#### Frentista
- **Horário:** Turno noturno / madrugada (antes da soltura)
- **Superior:** Líder de Pátio
- **Tela mobile:** `abastecimento` | **Tabela:** `abastecimento_checklist`

| Momento | Ação | Resultado |
|---------|------|-----------|
| Início do turno | Abre tela `abastecimento` | Vê frota: ✅ abastecidos / ○ pendentes |
| Para cada veículo | Toca no card | Registra litros Diesel + ARLA 32 + horário |
| Controle | Barra de progresso | Mostra % da frota abastecida |

**Gatilho:** Divergência volume vs. NF → Líder Almoxarifado + Coordenador (Tolerância Zero para diesel).

---

#### Plantão
- **Horário:** Turno noturno / madrugada (recolha)
- **Superior:** Líder Operacional / Supervisor
- **Tela mobile:** `recolha` | **Tabelas:** `recolha_checklist`, `avarias_recolha`

| Momento | Ação | Resultado |
|---------|------|-----------|
| Ao receber veículo | Abre tela `recolha` | Vê lista de frota com status |
| Para cada recolha | Toca no prefixo | Registra hora real, linha, motorista, tabela |
| Avaria detectada | Registra avaria | Cria registro com itens NOK |
| Fim do turno | Acompanha % | Garante todos os veículos registrados |

**Gatilho:** Sinistro em rua → acionar Líder Operacional imediatamente. Avaria crítica → Líder PCM/Oficina.

---

## 3. Gestão da Rotina

### 3.1 Contexto
Cadência operacional diária garantindo cobertura integral dos turnos. Desvios identificados em curtíssimo prazo via **Drumbeats** (rituais de alinhamento) e **Gemba Walks** (auditorias de campo).

### 3.2 Matriz de Cobertura — Férias / Afastamento / Ausência

| Cargo Titular | Substituto Principal |
|--------------|---------------------|
| Coordenador de Garagem | Líder PCM Diurno / Supervisor de Garagem |
| Supervisor de Garagem | Líder de PCM Noturno |
| Líder PCM Diurno | Assistente de PCM |
| Líder PCM Noturno | Assistente de PCM |
| Assistente de PCM | Líder de PCM do mesmo horário |
| Líder de Almoxarifado | Almoxarifes |
| Almoxarifes | Líder de Almoxarifado |
| Líder de Oficina Noturno | Líder PCM Noturno |
| Líder de Oficina Diurno | Líder PCM Diurno |
| Líder de Pátio | Supervisor de Garagem |
| Líder de Operação | Líder de Pátio (mesmo horário) + Supervisor garante soltura |

> Atividades críticas marcadas com `**` na rotina do cargo devem ser executadas mesmo na ausência do titular.

---

### 3.3 Rotinas Hora a Hora

#### Coordenador de Garagem (08:00 ~ 18:00)

| Horário | Atividade | Descrição | Input | Output | Para quem |
|---------|-----------|-----------|-------|--------|-----------|
| 08:00–08:30 | **Checkpoint Liderança | Com RH / Escalante / Líder PCM / Líder Suprimentos / Supervisor | Entendimento das demandas do turno anterior | 2.1 Fechamento Turno / BI Op. Seguras | Alinhamento + diretrizes para o dia | — |
| 08:30–09:00 | **Validação do Modelo | — | Verificação de todos os relatórios entregues (D-1) | Site | — | — |
| 09:00–10:00 | Demandas não previstas | — | — | — | — |
| 10:00–10:30 | **Gemba Walk Rodada 1 | Ronda operacional (Manutenção, Almox, Operação) | — | 3.3 Ronda Operacional Parcial | — |
| 10:30–11:00 | Fechamento orçamentário | Fechamento com todos os custos e desvios vs. orçado | 1.2 Cockpit Orçamento | 2.13 Relatório Orçamento | Coordenador |
| 11:00–12:00 | **Fechamento Técnico | Com Líder PCM, Operação, Almoxarifado | Validação status D-1 + cruzamento técnico | 2.12 Indicadores técnicos | 4.1 Plano de Ação → Op. Seguras | — |
| 12:00–13:00 | Refeição | Intervalo | — | — | — |
| 13:00–14:00 | **Drumbeat Matricial | Com Líderes (PCM/Almox/Op) | Tratar desvios e estancar falhas críticas | 2.12 Indicadores | 4.1 Plano de Ação atualizado | Matriz |
| 14:00–14:30 | Distribuição das ações | Após plano acordado com a Matriz | 4.1 Plano de Ação | 4.1 Plano Definido | Líderes PCM/Op/Almox |
| 14:30–15:00 | Follow-up Matricial | Interface com Matriz. Defesa do orçamento | 1.2 BI Orçamento | 2.13 Orçamento D-1 | — |
| 15:00–16:30 | Demandas não previstas | — | — | — | — |
| 16:30–17:00 | **Gemba Walk Rodada 2 | Verificação dos cestos de preventiva na oficina | 2.3 Fechamento Almox | 3.3 Ronda Operacional | — |
| 17:00–18:00 | **Fechamento do Dia | Consolidação KPIs + análise financeira. Direciona carros críticos para Supervisor Noturno | 2.12 + 2.6 + 4.1 | 2.1 Fechamento Turno | Supervisor Garagem |
| Semanal | Fechamento Orçamentário | Consolidação semanal de custos | 2.13 Orçamento Diário | 2.13 | Matriz |
| Semanal | Auditoria de Linha | Andar em 1 linha completa | — | — | — |
| Mensal | Acompanhamento Noturno | Supervisão atividades noturnas (2x/mês) | — | — | — |

---

#### Supervisor de Garagem (20:00 ~ 04:20, Dom ~ Sex)

| Horário | Atividade | Descrição | Input | Output | Para quem |
|---------|-----------|-----------|-------|--------|-----------|
| 20:00–20:30 | **Entendimento das demandas | Demandas do turno anterior | 2.1 Fechamento Turno | — | — |
| 20:30–21:30 | **Previsibilidade de manutenção | Com Líder PCM — análise liberação vs. custos | 2.6 Custo / 2.2 Priorização / 2.1 Fechamento | 2.2 Priorização Corretiva | Líder PCM |
| 21:30–22:30 | **Supervisão Manutenção Rodada 1 | Monitoramento preventivas e veículos indisponíveis | Prog. preventiva | 3.3 Ronda Operacional Parcial | — |
| 22:30–23:00 | **Auditoria Almoxarifado Rodada 1 | Supervisão separação de materiais + inventários rotativos | 2.3 Fechamento Almox / 2.9 Inventário | 3.3 Ronda Operacional | — |
| 23:30–00:30 | Verificação custos | Situação atual dos custos distribuídos | 2.2 Priorização / 2.6 Custo | Parcial (Aprovação) | Líder PCM |
| 00:30–01:30 | Demandas não previstas | — | — | — | — |
| 01:30–01:45 | Notificações de soltura | Carros disponíveis para soltura (faixas horárias) | Abastecer / Lavagem / Recolha / 2.1 Fechamento | 3.3 Ronda | — |
| 01:30–01:45 | Levantamento headcount | HC em cada preventiva + tempo estimado de execução | Manutenções realizadas | Relatório HC | — |
| 01:45–02:30 | Fechamento pré-soltura | Previsibilidade de soltura de frota | 3.1 Checklist lavagem | 2.10 Relatório Soltura | — |
| 02:30–03:00 | **Alinhamento Soltura Rodada 2 | Cenários de corte + dinâmica Pátio/PCM | 2.10 + 3.1 + 2.2 | 3.3 Ronda Final / Remanejamento | — |
| 03:00–03:30 | **Fechamento Setorial | Com Líder PCM — Encerramento da Oficina | 2.6 / 2.2 | 2.1 Fechamento Parcial | — |
| 03:30–04:00 | **Fechamento Almoxarifado | Fechamento do turno de almoxarifado | 2.3 Fechamento Almox | 2.1 Fechamento Parcial | — |
| 04:00–04:20 | **Relatório Geral | Consolidação status final (Manutenção, Suprimentos, Disponibilidade) | 2.3 + 3.3 + 2.6 | 2.1 Fechamento Final / 2.6 Aprovação | Coordenador |
| Semanal | Auditoria de Linha | Verificação operacional de 1 linha completa | — | — | — |
| Semanal | Conformidade PRAXIO | OS abertas sem baixa + requisições pendentes | — | — | — |
| Semanal | Sistema de emergência | Verificar 100% funcional | — | — | — |
| Semanal | Auditoria SOS | Consolidar relatórios de recolha anormal da semana | — | — | — |
| Mensal | Revisão Indicadores Noturnos | MKBF, CPK, indisponibilidade, eficiência soltura noturna | — | — | — |
| Mensal | Feedback de Equipe | Individual com líderes diretos | — | — | — |

---

## 4. Execução

### 4.1 Contexto
O sucesso da execução depende da capacidade de reagir rapidamente. **Regra de ouro:** Todo desvio identificado em Checklist ou BI deve gerar evidência diária. Se não resolvido em 24h, aciona a Cadeia de Ajuda.

### 4.2 Ferramentas por Cargo *(referência app JTP)*

| Código | Ferramenta | Cargos Principais |
|--------|------------|-------------------|
| 2.1 | Fechamento de Turno Garagem | Coordenador, Supervisor |
| 2.2 | Priorização / OS PCM | Líder PCM, Líder Oficina |
| 2.3 | Fechamento Almoxarifado | Líder Almoxarifado, Almoxarifes |
| 2.4 | Fechamento PCM | Líder PCM |
| 2.6 | Custo / Previsibilidade | Líder PCM, Coordenador |
| 2.10 | Relatório Soltura | Supervisor, Líder Pátio |
| 2.12 | Indicadores Técnicos | Coordenador, Líder PCM |
| 2.13 | Orçamento | Coordenador |
| 3.1 | Checklist Lavagem (app mobile) | Lavador, Líder Pátio |
| 3.3 | Ronda Operacional | Coordenador, Supervisor, Líder Operacional |
| 3.4 | Checklist Equipamentos | Líder PCM, Assistente PCM |
| SOL | Solicitações OS (aba mobile `valet_almox`) | Almoxarife — atender pedidos de peça originados de OS do PCM |
| CONF | Conferência de Turno (aba mobile `valet_almox`) | Almoxarife — passagem de bastão T-1 e Turno Atual |
| SAP-P | Preços SAP (desktop — catálogo importado via CSV) | Líder Suprimentos — referência de código e preço unitário por item |
| BOK | Rotina Operacional (este documento) | Todos os líderes |

---

### 4.3 Cadeia de Ajuda — Matriz de Encadeamento por Cargo

| Cargo | Gatilho (Desvio) | Evidência Diária | Escalada |
|-------|-----------------|-----------------|---------|
| Coordenador de Garagem | Desvio KPIs macros (MKBF, CPK); estouro orçamentário >5%; falha Cadeia Nível 1 | 1.2 BI Orçamento / Cockpit / Atas Drumbeat | Nível 2: Gerência Operações/Manutenção (Matriz) + Controladoria |
| Supervisor de Garagem | Quebra SLA Soltura; falha segurança em Gemba; interrupção fluxo noturno | 2.1 Fechamento / 3.3 Ronda / 2.10 Soltura | Nível 1: Coordenador. Acionamento imediato se impactar soltura |
| Líder PCM | Veículo parado >48h sem diagnóstico ou peça; falta kit preventiva D+1; desvio custo peças técnicas | 2.6 Previsibilidade / 1.1 BI Bacalhau / 2.5 Valetamento | Nível 1: Coordenador + Área Suprimentos (Matriz) |
| Assistente PCM | Erro KM/hodômetro no sistema; OS aberta sem baixa >24h; divergência RJNP | 2.4 Fechamento PCM / 3.4 Checklist / 2.8 RJNP | Nível 1: Líder PCM + Líder Oficina |
| Líder de Oficina | Retrabalho >3% no turno; falta MO técnica; falta ferramenta crítica para valeta | 3.2 Checklist Liberação / 2.7 Fechamento Oficina / BI MKBF | Nível 1: Líder PCM + Supervisor (Noite) |
| Líder de Almoxarifado | Divergência inventário rotativo >0%; divergência Diesel >0,5%; RECON paradas >72h | 2.9 Inventário / 2.12 Performance / Checklist Diesel | Nível 1: Coordenador + Auditoria/Supply Chain (Matriz) |
| Almoxarife | Falta de item em estoque para atender OS (→ Compra); item entregue diferente do pedido sem registro; baixas pendentes; divergência de recebimento | 2.3 Fechamento Almox / 2.9 Inventário / Aba Solicitações / Aba Conferência | Nível 1: Líder Suprimentos (falta de estoque/compra) + Líder PCM (divergência pedido × entregue em OS crítica) |
| Líder Operacional | Falta motorista para linha; veículo escalado não liberado; sinistro sem abertura de processo | 2.10 Soltura / BI Escala vs. Frota / Registro Sinistro | Nível 1: Coordenador + Supervisor (Madrugada) |
| Líder de Pátio | Lavagem <80% do planejado; gargalo abastecimento/manobra; vagas críticas bloqueadas | 3.1 Lavagem Diária / 2.10 Soltura / 3.3 Ronda | Nível 1: Supervisor + Líder Operacional |

---

### 4.4 Fluxo Solicitação de Peça via OS (PCM → Almoxarifado)

> Implementado em 22/06/2026. Substitui o processo verbal/manual de pedido de peça para OS corretivas.

**Atores:** Líder PCM / Assistente PCM (solicitante) + Almoxarife (atendente)

**Passo a passo:**

| Etapa | Quem | Onde | Ação |
|-------|------|------|------|
| 1 | PCM | Desktop `index.html` → OS ativa | Clica no botão 📦 ao lado do item SAP desejado |
| 2 | App | Automático | Cria registro em `requisicoes_compra` com `os_numero`, `prefixo`, `cod_sap`, quantidade e status `solicitado_pcm` |
| 3 | Almoxarife | Mobile `valet_almox` → aba **Solicitações** | Vê o pedido agrupado por OS; verifica item solicitado |
| 4 | Almoxarife | Mobile → botão **Separar** | Abre confirmação: pesquisa item real no catálogo SAP, registra código e quantidade entregues |
| 5 | App | Automático | Salva `item_entregue`, `cod_sap_entregue`, `qtd_entregue`; status → `separado` |
| 6 | PCM | Desktop ou mobile | Card exibe comparativo **Pedido × Entregue** — se houve substituição, aparece ✏️ |

**Regras do processo:**
- OS nunca é aberta/fechada pelo app — sempre no PRAXIO
- A solicitação de peça (📦) é feita dentro do app, vinculando ao número da OS
- Almoxarife **deve** registrar o que foi efetivamente entregue, mesmo que seja o mesmo item
- Se item pedido não existe em estoque → clicar **Compra** (status `pedido_compra`) → acionar Líder de Suprimentos
- Se item chegou após pedido de compra → clicar **Chegou**

---

### 4.6 Protocolo de Nemoto — Regras de Ouro da Cadeia de Ajuda

**Regra dos 40 Minutos (Oficina):** O Líder de Oficina monitora cada veículo em manutenção a cada 40 minutos. Se um veículo não avançou de estágio (diagnóstico → execução), acionar PCM imediatamente.

**Tolerância Zero para Divergência de Diesel:** Qualquer divergência NF vs. SAP vs. físico é Crítica Nível 1. Coordenador acionado no exato momento da detecção para validar contraprova antes da descarga.

**O "Corte" das 16:00h (Kit de Preventiva):** Se até 16:00h o Almoxarifado reportar indisponibilidade de itens para os cestos da noite, o Líder PCM deve escolher obrigatoriamente entre:
- Remanejamento do veículo na escala (via Escalante), ou
- Compra emergencial local → escalado para Coordenador.

**O Espírito do Protocolo:** Escalar um problema não é sinal de falha individual, mas ato de responsabilidade com o processo. A evidência (Checklist ou BI) é a prova de que o colaborador identificou, tratou ou elevou o ponto crítico dentro de 24h.

> "Não saber é aceitável no início. Não pedir ajuda e permitir que o erro se arraste é violação das diretrizes de performance da garagem."

---

### 4.7 FAQ — Guia de Contingências

**Q: O Escalante precisa de um carro, mas o Líder de Oficina diz que faltam 20 minutos. Quem decide?**
R: Segurança e integridade técnica prevalecem. Líder de Oficina mantém o veículo até concluir. Escalante aciona plano de contingência (veículo reserva/"coringa"). Se o atraso impactar a partida → Supervisor verifica se houve falha na Regra dos 40 Minutos.

**Q: Recebi uma peça de urgência mas o SAP/PRAXIO está fora do ar. Posso aplicar?**
R: A operação não para, mas o rastro não se perde. Almoxarife entrega a peça mediante protocolo manual assinado.

---

## 5. Diretrizes Corporativas

*(Conteúdo original preservado — seções 5.1, 5.2, 5.3 a serem expandidas quando solicitado via `/jtp-bok diretrizes`)*

---

## 6. Changelog

| Data | Versão | O que mudou | Autor |
|------|--------|------------|-------|
| 22/06/2026 | 1.2 | Almoxarife: seção de papel + rotina das 4 abas (Kits, Solicitações, Conferência, Inv. Rua) | /jtp-bok |
| 22/06/2026 | 1.2 | Assistente de PCM: seção de papel e atribuições adicionada | /jtp-bok |
| 22/06/2026 | 1.2 | Líder de Suprimentos: atribuição Quadro de Turnos incluída | /jtp-bok |
| 22/06/2026 | 1.2 | Novo fluxo documentado: Solicitação de Peça via OS (PCM → Almoxarifado) — seção 4.4 | /jtp-bok |
| 22/06/2026 | 1.2 | Seção 4.2 Ferramentas: SOL, CONF e SAP-P adicionados | /jtp-bok |
| 22/06/2026 | 1.2 | Seção 4.3 Cadeia de Ajuda: linha do Almoxarife atualizada com fluxo OS | /jtp-bok |
| 21/06/2026 | 1.1 | Lubrificador: seção completa (papel, lógica de rotação, rotina no app) | /jtp-bok sync |
| 21/06/2026 | 1.1 | Membros da ponta: rotinas de Lavador, Manobrista, Frentista e Plantão geradas a partir do app | /jtp-bok sync |
| 21/06/2026 | 1.0 | Conversão inicial do BOK_1.docx para markdown | /jtp-bok (setup) |
