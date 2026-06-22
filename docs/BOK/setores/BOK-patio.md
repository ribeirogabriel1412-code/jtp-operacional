# Setor: Pátio
> BOK JTP — Líder de Pátio, Manobrista, Lavador, Frentista, Lubrificador

---

## Líder de Pátio

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

**Rotina:** ⏳ Pendente — a ser importada

---

## Lubrificador

- **Horário:** Turno noturno (junto com o pátio)
- **Superior:** Líder de Pátio / Supervisor de Garagem
- **Telas mobile:** `lubrificacao` + `lubri_rel`
- **Tabela Supabase:** `checklist_lubrificacao`
- **Missão:** Executar a lubrificação sistemática de toda a frota seguindo o plano de rotação semanal, garantindo 100% de cobertura antes da soltura.

### Lógica de rotação
- **Frota VW** (Volkswagen/Volksbus): lubrificada **todos os dias**
- **Demais veículos**: divididos em **5 grupos** rotacionados de Seg a Sex
- **Fim de semana**: pendências da semana que não foram executadas

### Rotina no app

| Momento | Ação | Resultado |
|---------|------|-----------|
| Início do turno | Abre tela `lubrificacao` | Vê lista de hoje: VW + grupo do dia |
| Para cada veículo | Toca no card do prefixo | Abre confirmação de execução |
| Após executar | Marca ✅ | Registra em `checklist_lubrificacao` |
| Veículo extra | Botão `+` no topo | Registra fora da rotina |
| Fim do turno | Aba `Semana` | Verifica pendências e % de cobertura |

**Gatilho:** Produto em falta → Líder Almoxarifado. Defeito no sistema → Líder Oficina. % < 100% ao fechar → registrar no fechamento e comunicar ao Supervisor.

---

## Lavador

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

**Rotina detalhada:** ⏳ Pendente — a ser importada

---

## Manobrista

- **Horário:** Turno noturno / madrugada
- **Superior:** Líder de Pátio
- **Tela mobile:** `patio_man` | **Tabela:** `posicionamento_patio`

| Momento | Ação | Resultado |
|---------|------|-----------|
| Início do turno | Abre tela `patio_man` | Vê mapa do pátio por zona |
| Ao posicionar veículo | Seleciona zona e registra | Salva prefixo + zona + vaga |
| Verificação | Toca na zona | Vê veículos e quem registrou |

**Gatilho:** Vaga crítica bloqueada por veículo "morto" → acionar Líder de Pátio.

**Rotina detalhada:** ⏳ Pendente — a ser importada

---

## Frentista

- **Horário:** Turno noturno / madrugada (antes da soltura)
- **Superior:** Líder de Pátio
- **Tela mobile:** `abastecimento` | **Tabela:** `abastecimento_checklist`

| Momento | Ação | Resultado |
|---------|------|-----------|
| Início do turno | Abre tela `abastecimento` | Vê frota: ✅ abastecidos / ○ pendentes |
| Para cada veículo | Toca no card | Registra litros Diesel + ARLA 32 + horário |
| Controle | Barra de progresso | Mostra % da frota abastecida |

**Gatilho:** Divergência volume vs. NF → Líder Almoxarifado + Coordenador (Tolerância Zero para diesel).

**Rotina detalhada:** ⏳ Pendente — a ser importada
