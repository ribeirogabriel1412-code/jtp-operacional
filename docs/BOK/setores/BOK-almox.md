# Setor: Almoxarifado
> BOK JTP — Líder de Suprimentos, Almoxarife

---

## Líder de Suprimentos

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

**Rotina:** ⏳ Pendente — a ser importada

---

## Almoxarife

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

### Rotina no app — 4 abas do `valet_almox`

| Aba | Quando usar | O que faz |
|-----|-------------|-----------|
| **Kits** | Início do turno / tarde | Cestos de preventiva por data; verificar separação por veículo |
| **Solicitações** | Ao receber pedido do PCM | Ver itens solicitados via OS; confirmar entrega registrando item real + código SAP |
| **Conferência** | Virada de turno | Ver T-1 (turno anterior) e Turno Atual — só itens entregues — para passagem de bastão |
| **Inv. Rua** | Conforme escala de inventário | Contar itens físicos na rua atribuída e registrar no app |

### Rotina do turno

⏳ Pendente — a ser importada pelo Gabriel

### Gatilho de escalada

- Item entregue diferente do pedido → registrar na confirmação + comunicar Líder PCM
- Falta de item em estoque → acionar Líder de Suprimentos para pedido de compra emergencial
- Divergência de recebimento (NF × físico) → comunicar imediatamente ao Líder de Suprimentos
