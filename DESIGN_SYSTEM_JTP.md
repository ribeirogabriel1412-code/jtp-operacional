# Design System Oficial — Grupo JTP v1.0

> Padrão visual corporativo para aplicações desenvolvidas internamente.  
> Inspiração: SAP Fiori + Jira + Notion Enterprise + Power BI.

---

## Identidade

**Objetivo:** Criar aplicações corporativas premium, robustas, institucionais e exclusivas do Grupo JTP.

---

## Paleta Oficial (Light / Lovable)

| Token | Cor | Hex |
|-------|-----|-----|
| Azul Institucional | Principal | `#0A1E3F` |
| Azul Secundário | Hover/Surface | `#1E3A6E` |
| Azul Hover | Estado hover | `#13305E` |
| Dourado Institucional | Destaque | `#C8A24A` |
| Dourado Premium | Destaque suave | `#D8B86A` |
| Dourado Claro | Background dourado | `#E7D19A` |
| Fundo 1 | Branco puro | `#FFFFFF` |
| Fundo 2 | Off-white | `#F4F6FB` |
| Fundo 3 | Cinza claro | `#EEF2F7` |
| Fundo 4 | Cinza médio | `#E5E9F2` |
| Sucesso | Verde | `#2C7A4B` |
| Alerta | Âmbar | `#E0A800` |
| Erro | Vermelho | `#C0392B` |
| Informação | Azul info | `#2F80ED` |

---

## Paleta Dark Mode — App HTML

Interpretação corporativa da paleta para o app HTML monolítico (tema escuro):

```css
:root {
  --bg:       #0A1E3F;   /* azul institucional como fundo */
  --surface:  #0F2850;   /* camada de card */
  --surface2: #081730;   /* sidebar / drawer */
  --border:   #1E3A6E;   /* bordas */
  --border2:  #13305E;   /* bordas internas */
  --text:     #F4F6FB;   /* texto principal */
  --text2:    #C8A24A;   /* dourado — destaques */
  --text3:    #8FAABF;   /* texto secundário */
  --text4:    #4A6080;   /* texto terciário */
  --gold:     #C8A24A;   /* dourado institucional */
  --gold-light: #E7D19A; /* dourado claro */
  --blue:     #1E3A6E;   /* azul secundário (links, foco) */
  --blue-d:   #0A1E3F;   /* azul escuro */
  --green:    #2C7A4B;   /* sucesso */
  --amber:    #E0A800;   /* alerta */
  --red:      #C0392B;   /* erro */
  --sidebar:  240px;
}
```

---

## Tipografia

| Uso | Fonte | Peso |
|-----|-------|------|
| Títulos / Categorias | Cinzel | SemiBold (600) |
| Corpo / Labels | Montserrat | Regular (400), Medium (500), SemiBold (600), Bold (700) |

> App HTML atual usa **DM Sans** — migrar gradualmente para Montserrat nos textos e Cinzel nos títulos de seção.

```html
<!-- Google Fonts — adicionar no <head> -->
<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600&family=Montserrat:wght@400;500;600;700&display=swap" rel="stylesheet">
```

---

## Layout Padrão (Desktop)

- **Sidebar:** 240px, fundo azul institucional, logo no topo
- **Header/Topbar:** 72px, busca global, notificações, usuário e ação principal
- **Conteúdo:** largura máxima 1600px, padding 32px

---

## Componentes

### Cards
- `border-radius: 16px`
- Sombras suaves (`box-shadow: 0 2px 12px #00000020`)
- Visual limpo e executivo

### Botões
- **Primário:** fundo azul institucional `#0A1E3F`, texto branco
- **Secundário:** fundo branco / `--surface`, borda dourada `#C8A24A`

### Inputs
- `height: 44px`
- `border-radius: 10px`
- Focus: `border-color: #C8A24A` (dourado)

### Modais
- Preferência: **Drawer lateral** ou **Modal central**
- Evitar bottom sheets em desktop

### Animações
- Duração: 200ms–300ms
- Tipos: fade, slide, hover suave

---

## Dashboards

- KPIs executivos em destaque no topo
- Gráficos: Recharts (barras, linhas, donuts)
- Cores dos gráficos: paleta institucional (azul + dourado + verde + âmbar)

---

## Hierarquia Visual

1. **Categoria** — texto dourado (`#C8A24A`), Cinzel, uppercase
2. **Título** — texto principal, Cinzel SemiBold
3. **Descrição** — texto secundário, Montserrat Regular

---

## Stack Tecnológica (Lovable / novos projetos)

- React + TypeScript
- Tailwind CSS
- ShadCN/UI
- Lucide Icons
- Recharts

---

## PROIBIDO

- Gradientes exagerados ou "arco-íris"
- Visual gamer (neon, brilhos intensos)
- Glassmorphism
- Cores fora da paleta oficial
- Fontes aleatórias sem aprovação

---

## Objetivo Final

> Toda aplicação deve parecer um **sistema corporativo premium desenvolvido internamente pelo Grupo JTP**, combinando a robustez do SAP Fiori, a organização do Jira, a elegância do Notion Enterprise e a capacidade analítica do Power BI.
