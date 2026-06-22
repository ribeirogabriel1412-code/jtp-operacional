# BOK — Corpo do Conhecimento Operacional — Grupo JTP
> **Versão viva** — mantida pelo agente `/jtp-bok`.
> Última atualização: 22/06/2026 | Versão: 1.2

---

## Estrutura do BOK

| Arquivo | Setor | Cargos |
|---------|-------|--------|
| `BOK-gestao.md` | Gestão | Coordenador, Supervisor |
| `BOK-pcm.md` | PCM | Líder PCM, Assistente PCM, Líder de Oficina |
| `BOK-almox.md` | Almoxarifado | Líder de Suprimentos, Almoxarife |
| `BOK-operacional.md` | Operacional | Líder Operacional, Plantão |
| `BOK-patio.md` | Pátio | Líder de Pátio, Manobrista, Lavador, Frentista, Lubrificador |
| `BOK-execucao.md` | Execução | Ferramentas, Cadeia de Ajuda, Fluxos, Nemoto, FAQ |
| `BOK-diretrizes.md` | Diretrizes | Diretrizes Corporativas |

---

## Hierarquia e Organograma

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

## Matriz de Cobertura — Férias / Afastamento / Ausência

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

## Gerar .DOCX

```powershell
pandoc `
  "docs\BOK\setores\BOK-index.md" `
  "docs\BOK\setores\BOK-gestao.md" `
  "docs\BOK\setores\BOK-pcm.md" `
  "docs\BOK\setores\BOK-almox.md" `
  "docs\BOK\setores\BOK-operacional.md" `
  "docs\BOK\setores\BOK-patio.md" `
  "docs\BOK\setores\BOK-execucao.md" `
  "docs\BOK\setores\BOK-diretrizes.md" `
  -o "docs\BOK\BOK-completo.docx" `
  --reference-doc="docs\BOK\Base\BOK_1.docx" `
  --from markdown --to docx
```

---

## Changelog

| Data | Versão | O que mudou | Autor |
|------|--------|------------|-------|
| 22/06/2026 | 1.3 | BOK reestruturado em arquivos por setor | /jtp-bok |
| 22/06/2026 | 1.2 | Almoxarife: rotina das 4 abas; Assistente PCM; fluxo SOL; ferramentas SOL/CONF/SAP-P | /jtp-bok |
| 21/06/2026 | 1.1 | Lubrificador + Membros da Ponta (Lavador, Manobrista, Frentista, Plantão) | /jtp-bok sync |
| 21/06/2026 | 1.0 | Conversão inicial do BOK_1.docx para markdown | /jtp-bok (setup) |
