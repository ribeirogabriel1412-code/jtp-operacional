# Execução — Ferramentas, Cadeia de Ajuda e Protocolos
> BOK JTP — Referência cruzada de ferramentas, fluxos e escalada

---

## Ferramentas por Cargo *(referência app JTP)*

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

## Cadeia de Ajuda — Matriz de Encadeamento por Cargo

| Cargo | Gatilho (Desvio) | Evidência Diária | Escalada |
|-------|-----------------|-----------------|---------|
| Coordenador de Garagem | Desvio KPIs macros (MKBF, CPK); estouro orçamentário >5%; falha Cadeia Nível 1 | 1.2 BI Orçamento / Cockpit / Atas Drumbeat | Nível 2: Gerência Operações/Manutenção (Matriz) + Controladoria |
| Supervisor de Garagem | Quebra SLA Soltura; falha segurança em Gemba; interrupção fluxo noturno | 2.1 Fechamento / 3.3 Ronda / 2.10 Soltura | Nível 1: Coordenador. Acionamento imediato se impactar soltura |
| Líder PCM | Veículo parado >48h sem diagnóstico ou peça; falta kit preventiva D+1; desvio custo peças técnicas | 2.6 Previsibilidade / 1.1 BI Bacalhau / 2.5 Valetamento | Nível 1: Coordenador + Área Suprimentos (Matriz) |
| Assistente PCM | Erro KM/hodômetro no sistema; OS aberta sem baixa >24h; divergência RJNP | 2.4 Fechamento PCM / 3.4 Checklist / 2.8 RJNP | Nível 1: Líder PCM + Líder Oficina |
| Líder de Oficina | Retrabalho >3% no turno; falta MO técnica; falta ferramenta crítica para valeta | 3.2 Checklist Liberação / 2.7 Fechamento Oficina / BI MKBF | Nível 1: Líder PCM + Supervisor (Noite) |
| Líder de Almoxarifado | Divergência inventário rotativo >0%; divergência Diesel >0,5%; RECON paradas >72h | 2.9 Inventário / 2.12 Performance / Checklist Diesel | Nível 1: Coordenador + Auditoria/Supply Chain (Matriz) |
| Almoxarife | Falta de item em estoque para atender OS; item entregue diferente do pedido sem registro; baixas pendentes; divergência de recebimento | 2.3 Fechamento Almox / 2.9 Inventário / Aba Solicitações / Aba Conferência | Nível 1: Líder Suprimentos (falta estoque/compra) + Líder PCM (divergência OS crítica) |
| Líder Operacional | Falta motorista para linha; veículo escalado não liberado; sinistro sem abertura de processo | 2.10 Soltura / BI Escala vs. Frota / Registro Sinistro | Nível 1: Coordenador + Supervisor (Madrugada) |
| Líder de Pátio | Lavagem <80% do planejado; gargalo abastecimento/manobra; vagas críticas bloqueadas | 3.1 Lavagem Diária / 2.10 Soltura / 3.3 Ronda | Nível 1: Supervisor + Líder Operacional |

---

## Fluxo Solicitação de Peça via OS (PCM → Almoxarifado)

> Implementado em 22/06/2026. Substitui o processo verbal/manual de pedido de peça para OS corretivas.

**Atores:** Líder PCM / Assistente PCM (solicitante) + Almoxarife (atendente)

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

## Protocolo de Nemoto — Regras de Ouro da Cadeia de Ajuda

**Regra dos 40 Minutos (Oficina):** O Líder de Oficina monitora cada veículo em manutenção a cada 40 minutos. Se um veículo não avançou de estágio (diagnóstico → execução), acionar PCM imediatamente.

**Tolerância Zero para Divergência de Diesel:** Qualquer divergência NF vs. SAP vs. físico é Crítica Nível 1. Coordenador acionado no exato momento da detecção para validar contraprova antes da descarga.

**O "Corte" das 16:00h (Kit de Preventiva):** Se até 16:00h o Almoxarifado reportar indisponibilidade de itens para os cestos da noite, o Líder PCM deve escolher obrigatoriamente entre:
- Remanejamento do veículo na escala (via Escalante), ou
- Compra emergencial local → escalado para Coordenador.

**O Espírito do Protocolo:** Escalar um problema não é sinal de falha individual, mas ato de responsabilidade com o processo. A evidência (Checklist ou BI) é a prova de que o colaborador identificou, tratou ou elevou o ponto crítico dentro de 24h.

> "Não saber é aceitável no início. Não pedir ajuda e permitir que o erro se arraste é violação das diretrizes de performance da garagem."

---

## FAQ — Guia de Contingências

**Q: O Escalante precisa de um carro, mas o Líder de Oficina diz que faltam 20 minutos. Quem decide?**
R: Segurança e integridade técnica prevalecem. Líder de Oficina mantém o veículo até concluir. Escalante aciona plano de contingência (veículo reserva/"coringa"). Se o atraso impactar a partida → Supervisor verifica se houve falha na Regra dos 40 Minutos.

**Q: Recebi uma peça de urgência mas o SAP/PRAXIO está fora do ar. Posso aplicar?**
R: A operação não para, mas o rastro não se perde. Almoxarife entrega a peça mediante protocolo manual assinado.
