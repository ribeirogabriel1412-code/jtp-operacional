# Roadmap Estratégico — JTP App

> Documento vivo. Atualizado junto com o Claude a cada sessão de trabalho que avançar, destravar ou repriorizar algo aqui.
> Não é uma lista de desejos — é a ordem de execução acordada. Se a prioridade mudar, muda aqui primeiro, com o motivo registrado no log.

---

## Como usar este documento

1. No início de qualquer sessão estratégica (não de bug pontual), abrir este arquivo antes de decidir o que fazer.
2. Escolher o item de maior prioridade que **não está bloqueado**.
3. Ao concluir, pausar ou bloquear algo, atualizar o status na tabela **e** adicionar uma linha no [Log de decisões](#log-de-decisões) — com data e o porquê, não só o "o quê".
4. Reprioridade é normal. O que não é normal é mudar a ordem sem deixar rastro do motivo.

**Legenda de status:** 🔴 não iniciado · 🟡 em andamento · 🟢 concluído · ⏸️ bloqueado/pausado · 🌀 contínuo (sem "fim", revisar periodicamente)

---

## Visão geral das trilhas (por que essa ordem)

O critério de priorização é **risco × valor operacional × esforço**, não só "o que está pendente há mais tempo":

1. **Trilha 0 (Infra)** roda em paralelo — não consome nosso tempo de dev, só espera autorização. Não deve travar as outras.
2. **Trilha 1 (Cadeia crítica)** é o maior valor operacional parado: sem o Relatório de Liberação, o Histórico do carro no SOS nunca sai do papel, e é a peça que a operação mais sente falta no dia a dia.
3. **Trilha 2 (Débito técnico)** só sobe de prioridade quando toca código relacionado (ex: não corrigir timezone isolado — corrigir quando mexer em recolha/escala) ou quando o prazo do gatilho (expansão Acre) se aproximar.
4. **Trilha 3 (Motores)** é valor real mas não crítico ao dia a dia — continua em ritmo próprio, sem disputar prioridade com a Trilha 1.
5. **Trilha 4/5** ficam represadas até a Trilha 1 fechar — evita dispersão.

---

## Trilha 0 — Infraestrutura & Risco de Disponibilidade

| Item | Status | Bloqueado por | Próxima ação | Dono |
|---|---|---|---|---|
| Migração Supabase → Azure self-hosted | ⏸️ | Autorização TI/gestão nos Resource Groups | Cobrar retorno da autorização | Daniel/TI |
| Definir região, VNet, permissão `Contributor` | 🔴 | Item acima | — | TI |

**Por que importa:** hoje o app roda em Supabase free tier, sem SLA, sendo usado todo dia por motorista/mecânico/líder em produção. É o item de maior risco *silencioso* da lista — não aparece como bug até o dia que cair.

---

## Trilha 1 — Cadeia de Valor Crítica (Fase 1)

Ordem de construção é a ordem da tabela — cada linha depende da anterior.

| # | Item | Status | Depende de | Próxima ação |
|---|---|---|---|---|
| 1 | Relatório de Liberação de Veículo (PCM preenche ao fechar OS: checklist + mão de obra + peças) | 🔴 | — | Desenhar tela + tabela nova |
| 2 | Histórico do carro no SOS (plantão vê OS/avarias/KM ao abrir SOS) | 🔴 | Item 1 | — |
| 3 | Painel Estado da Frota (disponível · avaria · manutenção · prev. agendada · lavagem pendente) | 🔴 | — (independente) | Pode iniciar em paralelo |
| 4 | Painel diário de lavagem (programado vs confirmado vs pendente) | 🔴 | — (independente, já sinalizado como simples) | **Candidato a vitória rápida** |
| 5 | Visual indisponível no pátio (prazo de retorno + preventiva agendada) | 🔴 | Item 3 | — |
| 6 | Fase 4 sync PRAXIO — `praxio_os_itens`, resolver 401 (GRANT Supabase) | 🔴 | — | Rodar GRANT pendente no Supabase |

**Recomendação técnica:** abrir com o **item 4** (painel de lavagem — menor esforço, valor visível imediato) para gerar tração, e simultaneamente iniciar o **item 1** (maior cadeia de dependência, decisão mais lenta de desenhar). Itens 3/5/6 entram assim que 1 e 4 estiverem em andamento estável.

---

## Trilha 2 — Débito Técnico

| Item | Status | Gatilho para subir prioridade | Ação quando chegar a vez |
|---|---|---|---|
| `janelaOperacional()` sem timezone por garagem | 🔴 | Antes de expandir para Acre (UTC-5) ou antes de features de escala/Gool cruzadas | Adicionar timezone como parâmetro |
| RLS recorrente em tabela nova (403 até lembrar policy) | 🌀 | Todo `criar_*.sql` novo | Criar template SQL padrão com `ENABLE RLS + policy` já embutido, usar sempre a partir de agora |
| Hodômetro divergente (02.188/02.203/02.189) | ⏸️ | — (sensor, não bug de software) | Registrar ação de manutenção física fora do app |

---

## Trilha 3 — Motores de Análise (ritmo próprio)

| Motor | Status | Observação |
|---|---|---|
| Km/L (`VW_LANCAMENTOABASTECIMENTO`) | 🟢 | Validado contra painel oficial |
| Viagens perdidas | 🟢 | Validado nas 2 garagens |
| Pontualidade | 🟢 | Validado, ±11min, resíduo residual não crítico |
| Custo por veículo (peças/OS) | ⏸️ | Escala de preço no Oracle inconsistente — precisa TI/PCM confirmar regra |
| Cruzamento manutenção × viagens perdidas (`PI_MAN`) | ⏸️ | 470 vs 65 OS não reconciliado — precisa TI/PCM explicar filtro do painel oficial |
| OS abertas/fechadas (Cumprimento de Revisão) | 🟡 | Validado para preventiva pesada/leve; falta somar corretivas e consolidar motor único |

**Próxima ação concreta:** agendar 30min com TI/PCM para destravar os dois itens ⏸️ — é bloqueio de acesso a conhecimento, não de engenharia.

---

## Trilha 4 — Fase 2 Backlog (represada até Trilha 1 avançar)

| Módulo | Status |
|---|---|
| 1 — Almoxarifado (WMS, solicitação de peça, inventário) | 🔴 |
| 2 — Plantão Inteligente (SOS, dobras/absenteísmo, trocas) | 🟢 concluído — falta rodar 3 scripts SQL em produção |
| 3 — Escala (rastreio de mudanças via Gool System) | 🔴 |
| 4 — Motorista: Soltura × Recolha × Gool System | 🔴 |

**Pendência de deploy do Módulo 2 (ação simples, não é feature nova):** rodar `criar_plantao_sos.sql`, `criar_plantao_dobras_absenteismo.sql` + `fix_rls_plantao_dobras_absenteismo.sql`, `criar_plantao_trocas.sql` no Supabase de produção.

---

## Trilha 5 — Fase 3 e Integrações Futuras (não priorizado ainda)

Acurácia PRAXIO×SAP, IUP financeiro, garantia de peças, inventário rotativo, integrações Gool/VR Ponto/SAP/Telemetria. Fica fora de escopo ativo até as Trilhas 1–3 avançarem — evita dispersão.

---

## Log de decisões

| Data | O que mudou | Motivo |
|---|---|---|
| 2026-07-12 | Roadmap criado, consolidando plano completo (24/06), backlog Fase 2 (22/06→09/07) e motores de análise (04/07→05/07) numa ordem única priorizada | Daniel pediu plano estratégico único e dinâmico em vez de memórias fragmentadas por assunto |
