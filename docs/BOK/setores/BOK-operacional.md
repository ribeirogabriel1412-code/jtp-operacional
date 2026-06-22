# Setor: Operacional
> BOK JTP — Líder Operacional, Plantão

---

## Líder Operacional (Escalante)

- **Horário:** 07:00 ~ 17:00 (5x2)
- **Superior:** Coordenador / Supervisor
- **Equipe:** Plantão, Sinistro, Motoristas
- **Missão:** Viabilizar operação diária — alocação eficiente de motoristas e veículos, 100% das viagens planejadas.
- **Atribuições:**
  - Escala estratégica para preventiva (sem prejudicar a operação)
  - Gestão de escalas (legislação + acordos sindicais)
  - Controle e tratativa de sinistros (SLA, RH, Seguradora)
  - Mitigação de atrasos e desvios em tempo real

**Rotina:** ⏳ Pendente — a ser importada

---

## Plantão

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

**Rotina detalhada:** ⏳ Pendente — a ser importada
