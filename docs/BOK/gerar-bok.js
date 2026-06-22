const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, PageNumber, LevelFormat
} = require('docx');
const fs = require('fs');

// ── Paleta ────────────────────────────────────────────────────────────────────
const AZUL     = '1E3A5F';
const AMBER    = 'B45309';
const VERDE    = '15803D';
const CINZA1   = 'F1F5F9';  // fundo linhas pares
const CINZA2   = 'E2E8F0';  // borda tabela
const NOVO_BG  = 'FEF3C7';  // fundo badge NOVO
const UPD_BG   = 'DBEAFE';  // fundo badge ATUALIZADO
const BRANCO   = 'FFFFFF';

// ── Larguras (9360 = 6.5" com margem 1") ─────────────────────────────────────
const W = 9360;

// ── Bordas ────────────────────────────────────────────────────────────────────
const bThin = { style: BorderStyle.SINGLE, size: 1, color: CINZA2 };
const bNone = { style: BorderStyle.NONE,   size: 0, color: BRANCO };
const BORDERS     = { top: bThin, bottom: bThin, left: bThin, right: bThin };
const BORDERS_NONE= { top: bNone, bottom: bNone, left: bNone, right: bNone };

// ── Helpers básicos ───────────────────────────────────────────────────────────
const f = (text, opts={}) => new TextRun({ text: String(text||''), font:'Arial', size:20, ...opts });
const fBold = (text, opts={}) => f(text, { bold:true, ...opts });
const fMono = (text, opts={}) => f(text, { font:'Courier New', size:18, ...opts });

const p = (children, opts={}) => new Paragraph({
  children: Array.isArray(children) ? children : [f(children)],
  spacing: { after: opts.after ?? 80, before: opts.before ?? 0 },
  ...opts,
});

const ph = (text, level) => new Paragraph({
  heading: level,
  children: [new TextRun({ text, font:'Arial', bold:true,
    size: level===HeadingLevel.HEADING_1?32 : level===HeadingLevel.HEADING_2?26 : 22,
    color: AZUL })],
  spacing: { before: level===HeadingLevel.HEADING_1?360:240, after:120 },
});

const bullet = (text, bold=false) => new Paragraph({
  numbering: { reference:'bullets', level:0 },
  children: [bold ? fBold(text) : f(text)],
  spacing: { after:40 },
});

const badge = (texto, cor, bgHex) => new Paragraph({
  children: [new TextRun({ text: `  ${texto}  `, bold:true, font:'Arial', size:18,
    color: BRANCO, shading:{ type: ShadingType.CLEAR, fill: cor } })],
  shading: { type: ShadingType.CLEAR, fill: bgHex || cor },
  spacing: { before:80, after:80 },
  indent: { left:0 },
});

const linha = () => new Paragraph({
  border: { bottom:{ style:BorderStyle.SINGLE, size:3, color:CINZA2, space:1 } },
  children: [f('')], spacing:{ before:160, after:80 },
});

// Célula de tabela
const cel = (children, opts={}) => new TableCell({
  children: Array.isArray(children) ? children : [p(Array.isArray(children)?children:[typeof children==='string'?f(children):children])],
  width: opts.w ? { size: opts.w, type: WidthType.DXA } : undefined,
  shading: opts.bg ? { fill: opts.bg, type: ShadingType.CLEAR } : undefined,
  borders: opts.noBorder ? BORDERS_NONE : BORDERS,
  margins: { top:80, bottom:80, left:120, right:120 },
  verticalAlign: VerticalAlign.TOP,
  columnSpan: opts.span,
});

const celTxt = (text, opts={}) => cel([p([typeof text==='string'? (opts.bold?fBold(text,{color:opts.color}):f(text,{color:opts.color})) : text])], opts);

const headerRow = (cols, widths, bg=AZUL) => new TableRow({
  children: cols.map((c,i) => new TableCell({
    children: [p([fBold(c, { color:BRANCO, size:18 })])],
    width: widths[i] ? { size:widths[i], type:WidthType.DXA } : undefined,
    shading: { fill: bg, type: ShadingType.CLEAR },
    borders: BORDERS,
    margins: { top:80, bottom:80, left:120, right:120 },
  })),
  tableHeader: true,
});

const dataRow = (cols, widths, bg=BRANCO) => new TableRow({
  children: cols.map((c,i) => new TableCell({
    children: [p([typeof c==='string' ? f(c) : c])],
    width: widths[i] ? { size:widths[i], type:WidthType.DXA } : undefined,
    shading: { fill:bg, type:ShadingType.CLEAR },
    borders: BORDERS,
    margins: { top:80, bottom:80, left:120, right:120 },
  })),
});

// ── Helpers cargo ─────────────────────────────────────────────────────────────
const cargoHeader = (nome, horario, superior, telas, missao, isNew=false, isUpdated=false) => {
  const badge_run = isNew
    ? new TextRun({ text:'  ★ NOVO — 22/06/2026 ', bold:true, font:'Arial', size:18, color:BRANCO,
        shading:{type:ShadingType.CLEAR,fill:AMBER} })
    : isUpdated
    ? new TextRun({ text:'  ✏ ATUALIZADO — 22/06/2026 ', bold:true, font:'Arial', size:18, color:BRANCO,
        shading:{type:ShadingType.CLEAR,fill:'1D4ED8'} })
    : null;
  const titleRuns = [fBold(nome, { size:24, color:AZUL })];
  if (badge_run) { titleRuns.push(f('  ')); titleRuns.push(badge_run); }
  const rows = [
    new Paragraph({ children: titleRuns, spacing:{before:280,after:60}, heading: HeadingLevel.HEADING_3 }),
  ];
  if (horario) rows.push(p([fBold('Horário: ',{color:AZUL}), f(horario)], {after:30}));
  if (superior) rows.push(p([fBold('Superior: ',{color:AZUL}), f(superior)], {after:30}));
  if (telas) rows.push(p([fBold('Telas mobile: ',{color:AZUL}), fMono(telas)], {after:30}));
  rows.push(p([fBold('Missão: ',{color:AZUL}), f(missao)], {after:60}));
  return rows;
};

// ── Tabela simples (header + rows) ───────────────────────────────────────────
const tabelaSimples = (cols, widths, rows) => new Table({
  width: { size: W, type: WidthType.DXA },
  columnWidths: widths,
  rows: [
    headerRow(cols, widths),
    ...rows.map((r,i) => dataRow(r.map(c=>c), widths, i%2===0?BRANCO:CINZA1)),
  ],
});

// ═══════════════════════════════════════════════════════════════════════════════
// CONTEÚDO DO DOCUMENTO
// ═══════════════════════════════════════════════════════════════════════════════

const doc = new Document({
  numbering: {
    config: [{
      reference: 'bullets',
      levels: [{ level:0, format:LevelFormat.BULLET, text:'•', alignment:AlignmentType.LEFT,
        style:{ paragraph:{ indent:{ left:480, hanging:240 } } } }],
    }],
  },
  styles: {
    default: { document: { run: { font:'Arial', size:20 } } },
    paragraphStyles: [
      { id:'Heading1', name:'Heading 1', basedOn:'Normal', next:'Normal', quickFormat:true,
        run:{ size:34, bold:true, font:'Arial', color:AZUL },
        paragraph:{ spacing:{before:480,after:160}, outlineLevel:0,
          border:{ bottom:{ style:BorderStyle.SINGLE, size:4, color:AZUL, space:4 } } } },
      { id:'Heading2', name:'Heading 2', basedOn:'Normal', next:'Normal', quickFormat:true,
        run:{ size:26, bold:true, font:'Arial', color:AZUL },
        paragraph:{ spacing:{before:320,after:120}, outlineLevel:1 } },
      { id:'Heading3', name:'Heading 3', basedOn:'Normal', next:'Normal', quickFormat:true,
        run:{ size:22, bold:true, font:'Arial', color:AZUL },
        paragraph:{ spacing:{before:240,after:80}, outlineLevel:2 } },
    ],
  },
  sections: [{
    properties: {
      page: { size:{ width:12240, height:15840 }, margin:{ top:1080, right:1080, bottom:1080, left:1080 } },
    },
    headers: {
      default: new Header({ children:[
        new Paragraph({
          children:[ fBold('BOK 1 — Corpo do Conhecimento Operacional — Grupo JTP', {color:AZUL, size:18}),
                     f('      '), f('Versão 1.2  •  22/06/2026', {color:'6B7280', size:18}) ],
          border:{ bottom:{ style:BorderStyle.SINGLE, size:3, color:CINZA2, space:4 } },
        }),
      ]}),
    },
    footers: {
      default: new Footer({ children:[
        new Paragraph({
          alignment: AlignmentType.CENTER,
          children:[ f('Página ', {size:18, color:'6B7280'}),
                     new TextRun({ children:[PageNumber.CURRENT], size:18, color:'6B7280', font:'Arial' }),
                     f(' — Documento mantido pelo agente /jtp-bok. Não editar manualmente.', {size:18, color:'9CA3AF'}) ],
          border:{ top:{ style:BorderStyle.SINGLE, size:3, color:CINZA2, space:4 } },
        }),
      ]}),
    },
    children: [
      // ── CAPA ────────────────────────────────────────────────────────────────
      new Paragraph({ children:[ fBold('BOK 1', {size:72, color:AZUL}) ], spacing:{before:480,after:60}, alignment:AlignmentType.CENTER }),
      new Paragraph({ children:[ f('Corpo do Conhecimento Operacional', {size:30, color:'374151'}) ], spacing:{after:40}, alignment:AlignmentType.CENTER }),
      new Paragraph({ children:[ fBold('Grupo JTP Transportes', {size:24, color:AZUL}) ], spacing:{after:200}, alignment:AlignmentType.CENTER }),
      new Paragraph({
        children:[ new TextRun({ text:'  ★ VERSÃO 1.2 — ATUALIZADO EM 22/06/2026 — 7 MUDANÇAS APLICADAS  ', bold:true, font:'Arial', size:20, color:BRANCO }) ],
        shading:{ fill:AMBER, type:ShadingType.CLEAR },
        alignment:AlignmentType.CENTER,
        spacing:{ before:80, after:80 },
      }),
      p(''),
      // Resumo de mudanças desta versão
      ph('Mudanças desta versão (22/06/2026)', HeadingLevel.HEADING_2),
      tabelaSimples(
        ['#','O que mudou','Tipo'],
        [400, 7160, 1800],
        [
          ['1','Almoxarife — nova seção completa: papel, atribuições e rotina das 4 abas','✅ Novo'],
          ['2','Assistente de PCM — nova seção de papel e atribuições','✅ Novo'],
          ['3','Fluxo OS → Almoxarifado — processo formal documentado (seção 4.4)','✅ Novo'],
          ['4','Líder de Suprimentos — atribuição Quadro de Turnos incluída','✏ Atualiz.'],
          ['5','Almoxarife — rotinas das abas Solicitações e Conferência de Turno','✏ Atualiz.'],
          ['6','Seção 4.2 Ferramentas — SOL, CONF e SAP-Preços adicionados','✏ Atualiz.'],
          ['7','Seção 4.3 Cadeia de Ajuda — linha do Almoxarife ampliada com fluxo OS','✏ Atualiz.'],
        ]
      ),
      p(''),
      linha(),

      // ── SEÇÃO 1 ─────────────────────────────────────────────────────────────
      ph('1. Hierarquia e Organograma', HeadingLevel.HEADING_1),
      p([f('O '), fBold('Coordenador de Garagem'), f(' é o responsável integral da operação (turno diurno). O '),
         fBold('Supervisor de Garagem'), f(' atua em período noturno, em regime de corresponsabilidade.')], {after:120}),
      ph('Camada de liderança', HeadingLevel.HEADING_3),
      bullet('Líder de PCM'),
      bullet('Líder de Suprimentos'),
      bullet('Líder Operacional (Escalante)'),
      bullet('Líder de Pátio'),
      bullet('Líder de Oficina (garagens +80 veículos: Líder Mecânica, Líder Elétrica, Líder Funilaria, Líder Borracharia)'),
      bullet('Analista Administrativo'),
      bullet('Instrutor Operacional'),
      ph('Base operacional', HeadingLevel.HEADING_3),
      p('Manutenções, Almoxarifes, Assistentes de PCM, Plantão, Sinistros, Motoristas, Monitores Operacionais, Segurança do Trabalho.', {after:60}),
      p([fBold('NOTA: ', {color:AMBER}), f('Garagens até 80 veículos → Líder de Oficina. Garagens +80 → líderes de subáreas.')], {after:80}),
      linha(),

      // ── SEÇÃO 2 ─────────────────────────────────────────────────────────────
      ph('2. Papéis e Responsabilidades', HeadingLevel.HEADING_1),

      // Coordenador
      ...cargoHeader('Coordenador de Garagem','08:00 ~ 18:00','N3 Operações',null,
        'Orquestrar manutenção, operação e áreas administrativas para disponibilidade máxima da frota com menor custo.'),
      p([fBold('Indicadores-chave: ',{color:AZUL}), f('CPK, MKBF, gestão de suprimentos, absenteísmo/horas extras')],{after:40}),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Monitorar KPIs diários (soltura, pontualidade, limpeza, combustível, manutenção, suprimentos, pessoas)'),
      bullet('Controle orçamentário diário (guincho, peças, combustível, lubrificantes, pneus, serviços)'),
      bullet('Liderar Drumbeat Operacional + Gemba Walk'),
      bullet('Interface com Poder Concedente'),
      bullet('Gestão de pessoas da equipe completa'),
      linha(),

      // Supervisor
      ...cargoHeader('Supervisor de Garagem','20:00 ~ 04:20 (Dom ~ Sex)','Coordenador de Garagem',null,
        'Elo garantidor da disponibilidade máxima da frota e confiabilidade operacional noturna.'),
      p([fBold('Indicadores-chave: ',{color:AZUL}), f('Soltura de frota, conformidade limpeza/conservação, preventivas noturnas')],{after:40}),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Monitorar desvios em tempo real (soltura, pontualidade, limpeza)'),
      bullet('Gemba Walk nas frentes de pátio (abastecimento, manobra, lavagem)'),
      bullet('Auditar Almoxarifado, PCM e Oficina na madrugada'),
      bullet('Validar peças trocadas (foco itens > R$ 200)'),
      bullet('Passagem de bastão com líderes (PCM, Almox, Operação)'),
      bullet('Priorização estratégica da manutenção (tabelas paradas, custos)'),
      linha(),

      // Líder PCM
      ...cargoHeader('Líder PCM','Turno A 08:00~18:00 (5x2) | Turno B 20:00~04:20 (6x1)','Coordenador / Supervisor',null,
        'Cérebro estratégico da manutenção — dados em planos de ação para maximizar previsibilidade e minimizar custos.'),
      p([fBold('Indicadores-chave: ',{color:AZUL}), f('CPK, Cumprimento Preventiva, ciclo de vida pneus, MKBF')],{after:40}),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Garantir cumprimento do planejamento preventivo (kits + validação com almoxarifado)'),
      bullet('Supervisionar solicitação de peças (preventiva e corretiva)'),
      bullet('Distribuir demandas e definir prioridades de liberação de veículos'),
      bullet('Garantir acuracidade no PRAXIO (abertura/fechamento OS, serviços pendentes)'),
      bullet('Gestão de pessoas da equipe de manutenção'),
      linha(),

      // Líder de Oficina
      ...cargoHeader('Líder de Oficina','Turno A 08:00~16:20 (6x1) | Turno B 20:00~04:20 (6x1)','Líder de PCM',null,
        'Integridade técnica e confiabilidade dos veículos.'),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Controle de qualidade das OS (preventivas e corretivas)'),
      bullet('Diagnóstico técnico e liberação de veículos'),
      bullet('Distribuição e priorização de demandas para a equipe'),
      bullet('Ponto focal técnico para recolhas anormais, SOS e intercorrências'),
      bullet('Aprovação técnica de requisições de peças de alto valor'),
      linha(),

      // Assistente de PCM — NOVO
      ...cargoHeader('Assistente de PCM',
        'Turno A 08:00~16:20 (6x1) | Turno B 20:00~04:20 (6x1)',
        'Líder de PCM',
        'oficina (OS)  •  checklist_equip (3.4)  •  sos218 (2.18)  •  prev26 (2.6)',
        'Garantir rastreabilidade técnica das OS no PRAXIO e suporte operacional ao Líder PCM.',
        false, false),
      // badge manual
      new Paragraph({
        children:[ new TextRun({ text:'  ★ NOVO — 22/06/2026  ', bold:true, font:'Arial', size:18, color:BRANCO }) ],
        shading:{ fill:AMBER, type:ShadingType.CLEAR }, spacing:{before:0,after:80},
      }),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Abertura e fechamento de OS no PRAXIO (nunca pelo app — sistema de referência)'),
      bullet('Controle de KM/hodômetro e consistência de dados no sistema'),
      bullet('Acompanhar OS abertas sem baixa > 24h e acionar Líder PCM'),
      bullet('Executar checklist de equipamentos de segurança (ferramenta 3.4)'),
      bullet('Registrar e acompanhar SOS (ferramenta 2.18)'),
      bullet('Apoiar previsibilidade de custo (ferramenta 2.6)'),
      bullet('Garantir conformidade RJNP (relatório de irregularidades)'),
      linha(),

      // Líder de Suprimentos — ATUALIZADO
      ...cargoHeader('Líder de Suprimentos','07:00 ~ 17:00 (5x2)','Líder de Garagem (linha funcional: Supply Chain)',null,
        'Acuracidade do estoque e fluxo contínuo de suprimentos — zero indisponibilidade por falta de peças.'),
      new Paragraph({
        children:[ new TextRun({ text:'  ✏ ATUALIZADO — 22/06/2026: nova atribuição Quadro de Turnos  ', bold:true, font:'Arial', size:18, color:BRANCO }) ],
        shading:{ fill:'1D4ED8', type:ShadingType.CLEAR }, spacing:{before:0,after:80},
      }),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Inventários rotativos diários/semanais (divergência zero)'),
      bullet('Validar recebimento de materiais e combustível (Diesel) contra POs e NFs'),
      bullet('Garantir baixas do dia'),
      bullet('Gestão de RECON (peças para recuperação)'),
      bullet('Planejamento semanal de compras (mínimo/máximo)'),
      bullet('Preparação dos cestos de preventiva'),
      bullet('WMS e 5S no almoxarifado'),
      bullet('Configurar Quadro de Turnos dos Almoxarifes no Painel do Líder (desktop) — define horário de entrada e saída; base para a Conferência de Turno mobile', true),
      bullet('Gestão de pessoas do almoxarifado'),
      linha(),

      // Almoxarife — NOVO
      ...cargoHeader('Almoxarife',
        'Conforme escala (Quadro de Turnos configurado pelo Líder de Suprimentos)',
        'Líder de Suprimentos',
        'valet_almox  (4 abas: Kits • Solicitações • Conferência • Inv. Rua)',
        'Garantir disponibilidade de peças e materiais, atender solicitações do PCM com agilidade e manter acuracidade do estoque.'),
      new Paragraph({
        children:[ new TextRun({ text:'  ★ NOVO — 22/06/2026  ', bold:true, font:'Arial', size:18, color:BRANCO }) ],
        shading:{ fill:AMBER, type:ShadingType.CLEAR }, spacing:{before:0,after:80},
      }),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Preparar cestos de preventiva (Kits) conforme programação semanal'),
      bullet('Atender solicitações de peças oriundas de OS (aba Solicitações)'),
      bullet('Confirmar e registrar o que foi efetivamente entregue (com ou sem substituição de item)'),
      bullet('Conferir movimentações do turno anterior e atual (aba Conferência)'),
      bullet('Executar inventário da rua sob sua responsabilidade (aba Inv. Rua)'),
      bullet('Receber e conferir materiais contra NF e PO'),
      bullet('Comunicar divergências ao Líder de Suprimentos imediatamente'),
      p([fBold('Rotina no app — 4 abas do valet_almox:', {color:AZUL})],{before:120,after:60}),
      tabelaSimples(
        ['Aba','Quando usar','O que faz'],
        [1800, 3000, 4560],
        [
          ['Kits','Início do turno / tarde','Cestos de preventiva por data; verificar separação por veículo'],
          ['Solicitações','Ao receber pedido do PCM','Ver itens solicitados via OS; confirmar entrega registrando item real + código SAP'],
          ['Conferência','Virada de turno','Ver T-1 (turno anterior) e Turno Atual — só itens entregues — para passagem de bastão'],
          ['Inv. Rua','Conforme escala de inventário','Contar itens físicos na rua atribuída e registrar no app'],
        ]
      ),
      p([fBold('Gatilho de escalada: ',{color:AMBER}),
         f('Item entregue diferente do pedido → registrar na confirmação + comunicar Líder PCM. Falta de item em estoque → Líder de Suprimentos para pedido de compra emergencial.')],
        {before:120, after:80}),
      linha(),

      // Líder de Pátio
      ...cargoHeader('Líder de Pátio','22:00 ~ 07:20 (6x1)','Supervisor / Coordenador',null,
        'Organização, fluidez e confiabilidade da operação no pátio.'),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Coordenar disposição da frota conforme programação de saída'),
      bullet('Gerir manobristas (prioridades, integridade veicular, normas de segurança)'),
      bullet('Monitorar primeiras partidas + gestão de veículos "coringa"'),
      bullet('Validador final de higiene e estética dos veículos antes da liberação'),
      bullet('Acompanhar Realizado vs. Planejado das lavagens'),
      bullet('Checklist de entrada: registrar avarias, falhas mecânicas ou sinistros'),
      bullet('Transformar dados dos checklists em OS ou ações de manutenção'),
      linha(),

      // Líder Operacional
      ...cargoHeader('Líder Operacional (Escalante)','07:00 ~ 17:00 (5x2)','Coordenador / Supervisor',null,
        'Viabilizar operação diária — alocação eficiente de motoristas e veículos, 100% das viagens planejadas.'),
      p([fBold('Atribuições:',{color:AZUL})],{after:20}),
      bullet('Escala estratégica para preventiva (sem prejudicar a operação)'),
      bullet('Gestão de escalas (legislação + acordos sindicais)'),
      bullet('Controle e tratativa de sinistros (SLA, RH, Seguradora)'),
      bullet('Mitigação de atrasos e desvios em tempo real'),
      linha(),

      // Lubrificador
      ...cargoHeader('Lubrificador','Turno noturno (junto com o pátio)','Líder de Pátio / Supervisor',
        'lubrificacao  •  lubri_rel',
        'Executar a lubrificação sistemática de toda a frota seguindo o plano de rotação semanal.'),
      p([fBold('Lógica de rotação:',{color:AZUL})],{after:20}),
      bullet('Frota VW (Volksbus): lubrificada todos os dias', true),
      bullet('Demais veículos: divididos em 5 grupos rotacionados de Seg a Sex'),
      bullet('Fim de semana: pendências da semana não executadas'),
      p([fBold('Rotina no app:',{color:AZUL})],{before:120,after:60}),
      tabelaSimples(['Momento','Ação','Resultado'],[2800,3400,3160],[
        ['Início do turno','Abre tela lubrificacao','Vê lista: VW + grupo do dia'],
        ['Para cada veículo','Toca no card do prefixo','Abre confirmação de execução'],
        ['Após executar','Marca ✅','Registra em checklist_lubrificacao'],
        ['Veículo extra','Botão + no topo','Registra fora da rotina'],
        ['Fim do turno','Aba Semana','Verifica pendências e % de cobertura'],
      ]),
      linha(),

      // Membros da Ponta
      ph('Membros da Ponta', HeadingLevel.HEADING_2),
      ph('Lavador', HeadingLevel.HEADING_3),
      p([fBold('Horário: ',{color:AZUL}), f('Turno noturno (22:00 ~ 06:00 aprox.)  '), fBold('|  Superior: ',{color:AZUL}), f('Líder de Pátio  '), fBold('|  Tela: ',{color:AZUL}), fMono('lavagem')],{after:80}),
      tabelaSimples(['Momento','Ação','Resultado'],[2800,3400,3160],[
        ['Início do turno','Abre tela lavagem','Vê lista: Pesada / Média / Leve'],
        ['Para cada veículo','Toca no card','Abre checklist de lavagem'],
        ['Executa lavagem','Preenche e confirma','Status → executado'],
        ['Lavagem pesada','Acessa lav_pesada','Gestão específica preventiva'],
      ]),
      p([fBold('Gatilho: ',{color:AMBER}), f('Meta < 80% do planejado → acionar Líder de Pátio imediatamente.')],{before:80,after:80}),
      ph('Manobrista', HeadingLevel.HEADING_3),
      p([fBold('Horário: ',{color:AZUL}), f('Turno noturno / madrugada  '), fBold('|  Superior: ',{color:AZUL}), f('Líder de Pátio  '), fBold('|  Tela: ',{color:AZUL}), fMono('patio_man')],{after:80}),
      tabelaSimples(['Momento','Ação','Resultado'],[2800,3400,3160],[
        ['Início do turno','Abre tela patio_man','Vê mapa do pátio por zona'],
        ['Ao posicionar veículo','Seleciona zona e registra','Salva prefixo + zona + vaga'],
        ['Verificação','Toca na zona','Vê veículos e quem registrou'],
      ]),
      p([fBold('Gatilho: ',{color:AMBER}), f('Vaga crítica bloqueada por veículo "morto" → acionar Líder de Pátio.')],{before:80,after:80}),
      ph('Frentista', HeadingLevel.HEADING_3),
      p([fBold('Horário: ',{color:AZUL}), f('Turno noturno / madrugada (antes da soltura)  '), fBold('|  Tela: ',{color:AZUL}), fMono('abastecimento')],{after:80}),
      tabelaSimples(['Momento','Ação','Resultado'],[2800,3400,3160],[
        ['Início do turno','Abre tela abastecimento','Vê frota: ✅ abastecidos / ○ pendentes'],
        ['Para cada veículo','Toca no card','Registra litros Diesel + ARLA 32 + horário'],
        ['Controle','Barra de progresso','Mostra % da frota abastecida'],
      ]),
      p([fBold('Gatilho: ',{color:AMBER}), f('Divergência volume vs. NF → Líder Almoxarifado + Coordenador (Tolerância Zero para diesel).')],{before:80,after:80}),
      ph('Plantão', HeadingLevel.HEADING_3),
      p([fBold('Horário: ',{color:AZUL}), f('Turno noturno / madrugada (recolha)  '), fBold('|  Tela: ',{color:AZUL}), fMono('recolha')],{after:80}),
      tabelaSimples(['Momento','Ação','Resultado'],[2800,3400,3160],[
        ['Ao receber veículo','Abre tela recolha','Vê lista de frota com status'],
        ['Para cada recolha','Toca no prefixo','Registra hora real, linha, motorista, tabela'],
        ['Avaria detectada','Registra avaria','Cria registro com itens NOK'],
        ['Fim do turno','Acompanha %','Garante todos os veículos registrados'],
      ]),
      p([fBold('Gatilho: ',{color:AMBER}), f('Sinistro em rua → Líder Operacional imediatamente. Avaria crítica → Líder PCM/Oficina.')],{before:80,after:80}),
      linha(),

      // ── SEÇÃO 3 ─────────────────────────────────────────────────────────────
      ph('3. Gestão da Rotina', HeadingLevel.HEADING_1),
      ph('3.1 Contexto', HeadingLevel.HEADING_2),
      p('Cadência operacional diária garantindo cobertura integral dos turnos. Desvios identificados via Drumbeats (rituais de alinhamento) e Gemba Walks (auditorias de campo).',{after:80}),
      ph('3.2 Matriz de Cobertura — Férias / Afastamento / Ausência', HeadingLevel.HEADING_2),
      tabelaSimples(['Cargo Titular','Substituto Principal'],[4680,4680],[
        ['Coordenador de Garagem','Líder PCM Diurno / Supervisor de Garagem'],
        ['Supervisor de Garagem','Líder de PCM Noturno'],
        ['Líder PCM Diurno','Assistente de PCM'],
        ['Líder PCM Noturno','Assistente de PCM'],
        ['Assistente de PCM','Líder de PCM do mesmo horário'],
        ['Líder de Almoxarifado','Almoxarifes'],
        ['Almoxarifes','Líder de Almoxarifado'],
        ['Líder de Oficina Noturno','Líder PCM Noturno'],
        ['Líder de Oficina Diurno','Líder PCM Diurno'],
        ['Líder de Pátio','Supervisor de Garagem'],
        ['Líder de Operação','Líder de Pátio (mesmo horário) + Supervisor garante soltura'],
      ]),
      p(''),

      ph('3.3 Rotinas Hora a Hora', HeadingLevel.HEADING_2),
      ph('Coordenador de Garagem (08:00 ~ 18:00)', HeadingLevel.HEADING_3),
      new Table({
        width:{ size:W, type:WidthType.DXA }, columnWidths:[1100,1900,2560,1400,1400,1000],
        rows:[
          headerRow(['Horário','Atividade','Descrição','Input','Output','Para quem'],[1100,1900,2560,1400,1400,1000]),
          dataRow(['08:00–08:30','Checkpoint Liderança','Com RH / Escalante / Líder PCM / Suprimentos / Supervisor','2.1 Fechamento Turno','Alinhamento + diretrizes','—'],[1100,1900,2560,1400,1400,1000],BRANCO),
          dataRow(['08:30–09:00','Validação do Modelo','Verificação relatórios D-1','Site','—','—'],[1100,1900,2560,1400,1400,1000],CINZA1),
          dataRow(['10:00–10:30','Gemba Walk R1','Ronda operacional (Manutenção, Almox, Operação)','—','3.3 Ronda Parcial','—'],[1100,1900,2560,1400,1400,1000],BRANCO),
          dataRow(['11:00–12:00','Fechamento Técnico','Com Líder PCM, Operação, Almoxarifado','2.12 Indicadores','4.1 Plano de Ação','—'],[1100,1900,2560,1400,1400,1000],CINZA1),
          dataRow(['13:00–14:00','Drumbeat Matricial','Tratar desvios e estancar falhas','2.12 Indicadores','4.1 Plano Atualizado','Matriz'],[1100,1900,2560,1400,1400,1000],BRANCO),
          dataRow(['16:30–17:00','Gemba Walk R2','Verificar cestos de preventiva na oficina','2.3 Fechamento Almox','3.3 Ronda','—'],[1100,1900,2560,1400,1400,1000],CINZA1),
          dataRow(['17:00–18:00','Fechamento do Dia','Consolidação KPIs + análise financeira','2.12 + 2.6 + 4.1','2.1 Fechamento Turno','Supervisor'],[1100,1900,2560,1400,1400,1000],BRANCO),
        ],
      }),
      p(''),
      ph('Supervisor de Garagem (20:00 ~ 04:20, Dom ~ Sex)', HeadingLevel.HEADING_3),
      new Table({
        width:{ size:W, type:WidthType.DXA }, columnWidths:[1100,1900,2560,1400,1400,1000],
        rows:[
          headerRow(['Horário','Atividade','Descrição','Input','Output','Para quem'],[1100,1900,2560,1400,1400,1000]),
          dataRow(['20:00–20:30','Entendimento das demandas','Demandas do turno anterior','2.1 Fechamento','—','—'],[1100,1900,2560,1400,1400,1000],BRANCO),
          dataRow(['20:30–21:30','Previsibilidade manutenção','Com Líder PCM — análise liberação vs. custos','2.6 / 2.2 / 2.1','2.2 Priorização','Líder PCM'],[1100,1900,2560,1400,1400,1000],CINZA1),
          dataRow(['22:30–23:00','Auditoria Almoxarifado R1','Supervisão separação materiais + inventários','2.3 / 2.9','3.3 Ronda','—'],[1100,1900,2560,1400,1400,1000],BRANCO),
          dataRow(['01:45–02:30','Fechamento pré-soltura','Previsibilidade de soltura','3.1 Lavagem','2.10 Soltura','—'],[1100,1900,2560,1400,1400,1000],CINZA1),
          dataRow(['03:30–04:00','Fechamento Almoxarifado','Fechamento do turno de almoxarifado','2.3 Almox','2.1 Parcial','—'],[1100,1900,2560,1400,1400,1000],BRANCO),
          dataRow(['04:00–04:20','Relatório Geral','Consolidação status final','2.3 + 3.3 + 2.6','2.1 Final','Coordenador'],[1100,1900,2560,1400,1400,1000],CINZA1),
        ],
      }),
      p(''),
      linha(),

      // ── SEÇÃO 4 ─────────────────────────────────────────────────────────────
      ph('4. Execução', HeadingLevel.HEADING_1),
      p([fBold('Regra de ouro: ', {color:AMBER}),
         f('Todo desvio identificado em Checklist ou BI deve gerar evidência diária. Se não resolvido em 24h, aciona a Cadeia de Ajuda.')],{after:120}),

      ph('4.2 Ferramentas por Cargo (referência app JTP)', HeadingLevel.HEADING_2),
      new Paragraph({
        children:[ new TextRun({ text:'  ✏ ATUALIZADO — 22/06/2026: SOL, CONF e SAP-P adicionados  ', bold:true, font:'Arial', size:18, color:BRANCO }) ],
        shading:{ fill:'1D4ED8', type:ShadingType.CLEAR }, spacing:{before:80,after:80},
      }),
      new Table({
        width:{ size:W, type:WidthType.DXA }, columnWidths:[1000, 4560, 3800],
        rows:[
          headerRow(['Código','Ferramenta','Cargos Principais'],[1000,4560,3800]),
          dataRow(['2.1','Fechamento de Turno Garagem','Coordenador, Supervisor'],[1000,4560,3800],BRANCO),
          dataRow(['2.2','Priorização / OS PCM','Líder PCM, Líder Oficina'],[1000,4560,3800],CINZA1),
          dataRow(['2.3','Fechamento Almoxarifado','Líder Almoxarifado, Almoxarifes'],[1000,4560,3800],BRANCO),
          dataRow(['2.4','Fechamento PCM','Líder PCM'],[1000,4560,3800],CINZA1),
          dataRow(['2.6','Custo / Previsibilidade','Líder PCM, Coordenador'],[1000,4560,3800],BRANCO),
          dataRow(['2.10','Relatório Soltura','Supervisor, Líder Pátio'],[1000,4560,3800],CINZA1),
          dataRow(['2.12','Indicadores Técnicos','Coordenador, Líder PCM'],[1000,4560,3800],BRANCO),
          dataRow(['2.13','Orçamento','Coordenador'],[1000,4560,3800],CINZA1),
          dataRow(['3.1','Checklist Lavagem (mobile)','Lavador, Líder Pátio'],[1000,4560,3800],BRANCO),
          dataRow(['3.3','Ronda Operacional','Coordenador, Supervisor, Líder Operacional'],[1000,4560,3800],CINZA1),
          dataRow(['3.4','Checklist Equipamentos','Líder PCM, Assistente PCM'],[1000,4560,3800],BRANCO),
          new TableRow({ children:[
            new TableCell({ children:[p([fBold('SOL',{color:BRANCO})])], width:{size:1000,type:WidthType.DXA},
              shading:{fill:AMBER,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p([fBold('Solicitações OS — aba mobile valet_almox',{color:AZUL})])], width:{size:4560,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p('Almoxarife — atender pedidos de peça originados de OS do PCM')], width:{size:3800,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
          ]}),
          new TableRow({ children:[
            new TableCell({ children:[p([fBold('CONF',{color:BRANCO})])], width:{size:1000,type:WidthType.DXA},
              shading:{fill:AMBER,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p([fBold('Conferência de Turno — aba mobile valet_almox',{color:AZUL})])], width:{size:4560,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p('Almoxarife — passagem de bastão T-1 e Turno Atual')], width:{size:3800,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
          ]}),
          new TableRow({ children:[
            new TableCell({ children:[p([fBold('SAP-P',{color:BRANCO})])], width:{size:1000,type:WidthType.DXA},
              shading:{fill:AMBER,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p([fBold('Preços SAP — catálogo desktop (importação CSV)',{color:AZUL})])], width:{size:4560,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p('Líder Suprimentos — referência de código e preço unitário por item')], width:{size:3800,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
          ]}),
          dataRow(['BOK','Rotina Operacional (este documento)','Todos os líderes'],[1000,4560,3800],CINZA1),
        ],
      }),
      p(''),

      ph('4.3 Cadeia de Ajuda — Matriz de Encadeamento por Cargo', HeadingLevel.HEADING_2),
      new Paragraph({
        children:[ new TextRun({ text:'  ✏ ATUALIZADO — 22/06/2026: linha do Almoxarife expandida com fluxo OS  ', bold:true, font:'Arial', size:18, color:BRANCO }) ],
        shading:{ fill:'1D4ED8', type:ShadingType.CLEAR }, spacing:{before:80,after:80},
      }),
      new Table({
        width:{ size:W, type:WidthType.DXA }, columnWidths:[1800, 2800, 2560, 2200],
        rows:[
          headerRow(['Cargo','Gatilho (Desvio)','Evidência Diária','Escalada'],[1800,2800,2560,2200]),
          dataRow(['Coordenador','Desvio KPIs macros; estouro orçamentário >5%','1.2 BI Orçamento / Cockpit','Nível 2: Gerência Operações/Manutenção + Controladoria'],[1800,2800,2560,2200],BRANCO),
          dataRow(['Supervisor','Quebra SLA Soltura; falha segurança em Gemba','2.1 Fechamento / 3.3 Ronda','Nível 1: Coordenador. Imediato se impactar soltura'],[1800,2800,2560,2200],CINZA1),
          dataRow(['Líder PCM','Veículo parado >48h; falta kit preventiva D+1','2.6 Previsibilidade / BI Bacalhau','Nível 1: Coordenador + Suprimentos (Matriz)'],[1800,2800,2560,2200],BRANCO),
          dataRow(['Assistente PCM','Erro KM/hodômetro; OS sem baixa >24h; divergência RJNP','2.4 Fechamento PCM / 3.4 Checklist','Nível 1: Líder PCM + Líder Oficina'],[1800,2800,2560,2200],CINZA1),
          dataRow(['Líder de Oficina','Retrabalho >3%; falta MO técnica; falta ferramenta','3.2 Checklist / 2.7 Fechamento / BI MKBF','Nível 1: Líder PCM + Supervisor (Noite)'],[1800,2800,2560,2200],BRANCO),
          dataRow(['Líder de Almoxarifado','Divergência inventário >0%; divergência Diesel >0,5%','2.9 Inventário / 2.12 Performance','Nível 1: Coordenador + Auditoria/Supply Chain'],[1800,2800,2560,2200],CINZA1),
          new TableRow({ children:[
            new TableCell({ children:[p([fBold('Almoxarife',{color:AZUL})])], width:{size:1800,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p('Falta de item para OS (→ Compra); item entregue ≠ pedido sem registro; baixas pendentes')], width:{size:2800,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p('2.3 Almox / 2.9 Inventário / Aba Solicitações / Aba Conferência')], width:{size:2560,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p('Nível 1: Líder Suprimentos (estoque) + Líder PCM (divergência pedido × entregue em OS crítica)')], width:{size:2200,type:WidthType.DXA},
              shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
          ]}),
          dataRow(['Líder Operacional','Falta motorista; veículo escalado não liberado','2.10 Soltura / BI Escala vs. Frota','Nível 1: Coordenador + Supervisor'],[1800,2800,2560,2200],CINZA1),
          dataRow(['Líder de Pátio','Lavagem <80%; gargalo abastecimento; vagas bloqueadas','3.1 Lavagem / 2.10 Soltura / 3.3 Ronda','Nível 1: Supervisor + Líder Operacional'],[1800,2800,2560,2200],BRANCO),
        ],
      }),
      p([fBold('  ★ Células em amarelo = novo ou atualizado em 22/06/2026',{color:AMBER})],{before:60,after:120}),

      // 4.4 Fluxo OS — NOVO
      ph('4.4 Fluxo Solicitação de Peça via OS (PCM → Almoxarifado)', HeadingLevel.HEADING_2),
      new Paragraph({
        children:[ new TextRun({ text:'  ★ NOVO — 22/06/2026 — substitui processo verbal/manual de pedido de peça  ', bold:true, font:'Arial', size:18, color:BRANCO }) ],
        shading:{ fill:AMBER, type:ShadingType.CLEAR }, spacing:{before:0,after:80},
      }),
      p([fBold('Atores: ',{color:AZUL}), f('Líder PCM / Assistente PCM (solicitante)  +  Almoxarife (atendente)')],{after:80}),
      new Table({
        width:{ size:W, type:WidthType.DXA }, columnWidths:[700, 1500, 2360, 4800],
        rows:[
          headerRow(['Etapa','Quem','Onde','Ação'],[700,1500,2360,4800]),
          dataRow(['1','PCM','Desktop → OS ativa','Clica no botão 📦 ao lado do item SAP desejado'],[700,1500,2360,4800],BRANCO),
          dataRow(['2','App','Automático','Cria registro em requisicoes_compra com os_numero, prefixo, cod_sap e status solicitado_pcm'],[700,1500,2360,4800],CINZA1),
          dataRow(['3','Almoxarife','Mobile valet_almox → aba Solicitações','Vê pedido agrupado por OS; verifica item solicitado'],[700,1500,2360,4800],BRANCO),
          dataRow(['4','Almoxarife','Mobile → botão Separar','Pesquisa item real no catálogo SAP, registra código e quantidade entregues'],[700,1500,2360,4800],CINZA1),
          dataRow(['5','App','Automático','Salva item_entregue, cod_sap_entregue, qtd_entregue; status → separado'],[700,1500,2360,4800],BRANCO),
          dataRow(['6','PCM','Desktop ou mobile','Card exibe comparativo Pedido × Entregue — se houve substituição, aparece ✏️'],[700,1500,2360,4800],CINZA1),
        ],
      }),
      p([fBold('Regras: ',{color:AZUL})],{before:120,after:20}),
      bullet('OS nunca aberta/fechada pelo app — sempre no PRAXIO'),
      bullet('Solicitação de peça (📦) feita dentro do app, vinculando ao número da OS'),
      bullet('Almoxarife deve registrar o que foi efetivamente entregue, mesmo que seja o mesmo item', true),
      bullet('Item sem estoque → clicar Compra (status pedido_compra) → acionar Líder de Suprimentos'),
      bullet('Item chegou após pedido de compra → clicar Chegou'),
      p(''),

      ph('4.6 Protocolo de Nemoto — Regras de Ouro da Cadeia de Ajuda', HeadingLevel.HEADING_2),
      p([fBold('Regra dos 40 Minutos (Oficina): ',{color:AMBER}), f('O Líder de Oficina monitora cada veículo em manutenção a cada 40 minutos. Se não avançou de estágio, acionar PCM imediatamente.')],{after:80}),
      p([fBold('Tolerância Zero para Divergência de Diesel: ',{color:AMBER}), f('Qualquer divergência NF vs. SAP vs. físico é Crítica Nível 1. Coordenador acionado no exato momento da detecção.')],{after:80}),
      p([fBold('O "Corte" das 16:00h (Kit de Preventiva): ',{color:AMBER}), f('Se até 16:00h o Almoxarifado reportar indisponibilidade de itens para os cestos da noite, o Líder PCM deve escolher:')],{after:40}),
      bullet('Remanejamento do veículo na escala (via Escalante), ou'),
      bullet('Compra emergencial local → escalado para Coordenador.'),
      p([fBold('"',{size:22}), f('Não saber é aceitável no início. Não pedir ajuda e permitir que o erro se arraste é violação das diretrizes de performance da garagem.', {italics:true}), fBold('"',{size:22})],{before:120,after:60}),

      ph('4.7 FAQ — Guia de Contingências', HeadingLevel.HEADING_2),
      p([fBold('Q: O Escalante precisa de um carro, mas o Líder de Oficina diz que faltam 20 minutos. Quem decide? ',{color:AZUL})],{after:20}),
      p('R: Segurança e integridade técnica prevalecem. Líder de Oficina mantém o veículo até concluir. Escalante aciona plano de contingência. Se o atraso impactar a partida → Supervisor verifica falha na Regra dos 40 Minutos.',{after:80}),
      p([fBold('Q: Recebi uma peça de urgência mas o SAP/PRAXIO está fora do ar. Posso aplicar? ',{color:AZUL})],{after:20}),
      p('R: A operação não para, mas o rastro não se perde. Almoxarife entrega a peça mediante protocolo manual assinado.',{after:80}),
      linha(),

      // ── SEÇÃO 5 ─────────────────────────────────────────────────────────────
      ph('5. Diretrizes Corporativas', HeadingLevel.HEADING_1),
      p('(Conteúdo original preservado — seções 5.1, 5.2, 5.3 a serem expandidas quando solicitado via /jtp-bok diretrizes)',{after:80}),
      linha(),

      // ── SEÇÃO 6 ─────────────────────────────────────────────────────────────
      ph('6. Changelog — Histórico de Atualizações', HeadingLevel.HEADING_1),
      new Table({
        width:{ size:W, type:WidthType.DXA }, columnWidths:[1300, 800, 5660, 1600],
        rows:[
          headerRow(['Data','Versão','O que mudou','Autor'],[1300,800,5660,1600]),
          new TableRow({ children:[
            new TableCell({ children:[p([fBold('22/06/2026',{color:AMBER})])], width:{size:1300,type:WidthType.DXA}, shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p([fBold('1.2',{color:AMBER})])], width:{size:800,type:WidthType.DXA}, shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[
              p([fBold('Almoxarife: ',{color:AZUL}), f('seção de papel + rotina das 4 abas (Kits, Solicitações, Conferência, Inv. Rua)')],{after:30}),
              p([fBold('Assistente de PCM: ',{color:AZUL}), f('seção de papel e atribuições adicionada')],{after:30}),
              p([fBold('Líder de Suprimentos: ',{color:AZUL}), f('atribuição Quadro de Turnos incluída')],{after:30}),
              p([fBold('Fluxo OS → Almoxarifado: ',{color:AZUL}), f('processo formal documentado (seção 4.4)')],{after:30}),
              p([fBold('Seção 4.2 Ferramentas: ',{color:AZUL}), f('SOL, CONF e SAP-P adicionados')],{after:30}),
              p([fBold('Seção 4.3 Cadeia de Ajuda: ',{color:AZUL}), f('linha do Almoxarife ampliada com fluxo OS')],{after:0}),
            ], width:{size:5660,type:WidthType.DXA}, shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
            new TableCell({ children:[p('/jtp-bok')], width:{size:1600,type:WidthType.DXA}, shading:{fill:NOVO_BG,type:ShadingType.CLEAR}, borders:BORDERS, margins:{top:80,bottom:80,left:120,right:120} }),
          ]}),
          dataRow(['21/06/2026','1.1','Lubrificador: seção completa (papel, lógica de rotação, rotina no app)','/jtp-bok'],[1300,800,5660,1600],CINZA1),
          dataRow(['21/06/2026','1.1','Membros da ponta: rotinas de Lavador, Manobrista, Frentista e Plantão','/jtp-bok'],[1300,800,5660,1600],BRANCO),
          dataRow(['21/06/2026','1.0','Conversão inicial do BOK_1.docx para markdown','/jtp-bok (setup)'],[1300,800,5660,1600],CINZA1),
        ],
      }),
      p(''),
    ],
  }],
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('docs/BOK/BOK-v1.2-22jun2026.docx', buf);
  console.log('✅ BOK-v1.2-22jun2026.docx gerado com sucesso');
});
