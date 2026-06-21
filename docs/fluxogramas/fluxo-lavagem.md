# Fluxograma — Processo de Lavagem

**Processo:** Lavagem de ônibus (turno)  
**Cargos envolvidos:** Lavador, Líder de Pátio  
**Atualizado em:** 21/06/2026

---

## Diagrama de Fluxo

```mermaid
flowchart TD
    A([🌅 Início do Turno]) --> B[Lavador abre o app JTP]
    B --> C{Programação\ndo dia existe?}
    C -->|❌ Não aparece nada| D[Avisa Líder de Pátio]
    D --> E[Líder faz a programação]
    E --> B
    C -->|✅ Sim| F[Escolhe um ônibus da lista]

    F --> G{Tipo de\nlavagem?}

    G -->|🟢 Leve| H[Varrer + Retirar lixo\nVerificar janelas]
    G -->|💧 Simples| I[Varrer, secar carroceria\nLimpar vidros + cockpit]
    G -->|🔵 Média| J[Lavar carroceria\nEscovar balaustres\nLimpar vidros e piso]
    G -->|🟡 Pesada| K[Processo completo:\nChassis + Carroceria\nVideros + Teto + Filtros A/C]
    G -->|🟣 Preventiva| L[Básico + Chassis\nVidros internos]

    H --> M[Marca itens no checklist do app]
    I --> M
    J --> M
    K --> M
    L --> M

    M --> N{Todos os itens\nmarcados?}
    N -->|❌ Não| M
    N -->|✅ Sim| O[Toca em ✅ Confirmar]

    O --> P[(checklist_lavagem\nstatus = executado\nhora_executado = agora\nexecutado_por = nome)]

    P --> Q{Ônibus\nprecisa validação\ndo líder?}

    Q -->|🟡 Pesada / Preventiva| R[Líder de Pátio abre app]
    Q -->|Demais tipos| S[Próximo ônibus]

    R --> T[Líder toca no ônibus\nem ✅ para validar]
    T --> U{Aprovado?}
    U -->|✅ Sim| V[(checklist_lavagem\nvalidado_patio = true\nvalidado_por = líder\nvalidado_em = agora)]
    U -->|❌ Não aprovado| W[(checklist_lavagem\nstatus = pendente\nDevolvido para refazer)]
    W --> F

    V --> S
    S --> X{Todos os\nônibus feitos?}
    X -->|❌ Não| F
    X -->|✅ Sim| Y[Líder faz Fechamento de Turno]
    Y --> Z([🌙 Turno de Lavagem Encerrado])

    style A fill:#0A1E3F,color:#fff
    style Z fill:#2C7A4B,color:#fff
    style P fill:#1E3A6E,color:#C8A24A
    style V fill:#1E3A6E,color:#C8A24A
    style W fill:#C0392B,color:#fff
```

---

## Interações com o Banco de Dados (Supabase)

| Evento | Tabela | Ação | Quem faz |
|--------|--------|------|----------|
| Lavador confirma lavagem | `checklist_lavagem` | UPDATE: status → `executado`, hora_executado, executado_por | Lavador |
| Lavador marca "Não realizado" | `checklist_lavagem` | UPDATE: status → `nao_realizado` | Lavador |
| Lavador desfaz registro | `checklist_lavagem` | UPDATE: status → `pendente`, limpa hora e nome | Lavador |
| Lavagem Leve em lote | `checklist_lavagem` | UPDATE em todos os leves pendentes da garagem do dia | Lavador |
| Líder valida lavagem | `checklist_lavagem` | UPDATE: validado_patio → true, validado_por, validado_em | Líder de Pátio |
| Líder reprova lavagem | `checklist_lavagem` | UPDATE: validado_patio → false, status → pendente | Líder de Pátio |

---

## Pontos de Decisão

| Ponto | Opções | Impacto |
|-------|--------|---------|
| Programação existe? | Sim / Não | Se não, o turno não pode começar — bloqueia o lavador |
| Tipo da lavagem | Leve / Simples / Média / Pesada / Preventiva | Define o checklist e o tempo estimado |
| Todos os itens marcados? | Sim / Não | O botão Confirmar só ativa quando todos estão marcados |
| Ônibus saiu antes de ser lavado? | Sim / Não | Usar "Não realizado" + avisar líder |
| Lavagem pesada aprovada pelo líder? | Sim / Não | Se não, volta para lavador refazer |

---

## Rede de Apoio — Lavagem

| Situação | Quem acionar |
|----------|-------------|
| Sem programação no app | Líder de Pátio |
| Ônibus saiu sem ser lavado | Líder de Pátio → Coordenador |
| App com erro / tela branca | Líder de Pátio |
| Produto de limpeza acabou | Líder de Pátio → Líder de Suprimentos |
| Lavagem pesada reprovada repetidamente | Líder de Pátio avalia / re-treina lavador |
