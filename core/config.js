// ── Constantes globais do app JTP Mobile ──────────────────

const TZ_OPERACIONAL_PADRAO = 'America/Manaus';

const CARGOS = {
  diretoria:'Diretoria', gerente_garagem:'Gerente', coordenador:'Coordenador',
  supervisor:'Supervisor', lider_pcm:'Líder PCM', assistente_pcm:'Ass. PCM',
  almoxarifado:'Almoxarifado', lider_almoxarifado:'Líder Almox.',
  lider_operacional:'L. Operacional', lider_suprimentos:'L. Suprimentos',
  operacoes_seguras:'Op. Seguras', lider_oficina:'L. Oficina',
  lider_patio:'L. Pátio', lavador:'Lavador', manobrista:'Manobrista',
  frentista:'Frentista', plantao:'Plantão', lubrificador:'Lubrificador'
};

const TELA_INICIO = {
  lavador:'lavagem', lider_patio:'patio', lider_oficina:'oficina',
  lider_pcm:'oficina', assistente_pcm:'oficina', almoxarifado:'valet_almox',
  lider_almoxarifado:'valet_almox', lider_suprimentos:'valet_almox',
  coordenador:'fech21', supervisor:'fech21', lider_operacional:'ronda33',
  manobrista:'patio_man', frentista:'abastecimento', plantao:'recolha',
  gerente_garagem:'fech21', gerente_operacional:'fech21', lubrificador:'lubrificacao'
};

const NAV = {
  lavador:       [{id:'lavagem',ic:'🚿',lb:'Lavagem'},{id:'home',ic:'🏠',lb:'Início'}],
  lider_patio:   [{id:'patio',ic:'✅',lb:'Validar'},{id:'patio_man',ic:'🚗',lb:'Zona'},{id:'soltura',ic:'🚌',lb:'Soltura'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'abastecimento',ic:'⛽',lb:'Abastec.'},{id:'lav_pesada',ic:'🚿',lb:'Lavagem'},{id:'home',ic:'🏠',lb:'Início'}],
  lider_operacional:[{id:'ronda33',ic:'👣',lb:'3.3'},{id:'patio_man',ic:'🚗',lb:'Pátio'},{id:'lubri_rel',ic:'🛢️',lb:'Lubri.'},{id:'home',ic:'🏠',lb:'Início'}],
  lider_oficina: [{id:'oficina',ic:'🔧',lb:'OS'},{id:'avarias',ic:'⚠️',lb:'Avarias'},{id:'valet_oficina',ic:'📦',lb:'Valet'},{id:'prev_oficina',ic:'🧰',lb:'Prev.'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'home',ic:'🏠',lb:'Início'}],
  lider_pcm:     [{id:'oficina',ic:'🔧',lb:'OS'},{id:'avarias',ic:'⚠️',lb:'Avarias'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'checklist_equip',ic:'📋',lb:'3.4'},{id:'sos218',ic:'🆘',lb:'2.18'},{id:'prev26',ic:'💰',lb:'2.6'},{id:'lubri_rel',ic:'🛢️',lb:'Lubri.'},{id:'home',ic:'🏠',lb:'Início'}],
  assistente_pcm:[{id:'oficina',ic:'🔧',lb:'OS'},{id:'avarias',ic:'⚠️',lb:'Avarias'},{id:'checklist_equip',ic:'📋',lb:'3.4'},{id:'sos218',ic:'🆘',lb:'2.18'},{id:'prev26',ic:'💰',lb:'2.6'},{id:'home',ic:'🏠',lb:'Início'}],
  almoxarifado:  [{id:'valet_almox',ic:'📦',lb:'Kits'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'home',ic:'🏠',lb:'Início'}],
  lider_almoxarifado:[{id:'valet_almox',ic:'📦',lb:'Kits'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'home',ic:'🏠',lb:'Início'}],
  lider_suprimentos: [{id:'valet_almox',ic:'📦',lb:'Kits'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'home',ic:'🏠',lb:'Início'}],
  coordenador:   [{id:'fech21',ic:'📋',lb:'2.1'},{id:'avarias',ic:'⚠️',lb:'Avarias'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'lubri_rel',ic:'🛢️',lb:'Lubri.'},{id:'home',ic:'🏠',lb:'Início'}],
  gerente_garagem:[{id:'fech21',ic:'📋',lb:'2.1'},{id:'avarias',ic:'⚠️',lb:'Avarias'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'lubri_rel',ic:'🛢️',lb:'Lubri.'},{id:'home',ic:'🏠',lb:'Início'}],
  gerente_operacional:[{id:'fech21',ic:'📋',lb:'2.1'},{id:'avarias',ic:'⚠️',lb:'Avarias'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'lubri_rel',ic:'🛢️',lb:'Lubri.'},{id:'home',ic:'🏠',lb:'Início'}],
  supervisor:    [{id:'fech21',ic:'📋',lb:'2.1'},{id:'avarias',ic:'⚠️',lb:'Avarias'},{id:'ronda33',ic:'👣',lb:'3.3'},{id:'soltura',ic:'🚌',lb:'Soltura'},{id:'abastecimento',ic:'⛽',lb:'Abast.'},{id:'recolha',ic:'🔑',lb:'Recolha'},{id:'lubri_rel',ic:'🛢️',lb:'Lubri.'},{id:'home',ic:'🏠',lb:'Início'}],
  manobrista:    [{id:'patio_man',ic:'🚗',lb:'Pátio'},{id:'home',ic:'🏠',lb:'Início'}],
  frentista:     [{id:'abastecimento',ic:'⛽',lb:'Abastecer'},{id:'home',ic:'🏠',lb:'Início'}],
  plantao:       [{id:'recolha',ic:'🔑',lb:'Recolha'},{id:'home',ic:'🏠',lb:'Início'}],
  lubrificador:  [{id:'lubrificacao',ic:'🛢️',lb:'Lubr.'},{id:'lubri_rel',ic:'📋',lb:'Relatório'},{id:'home',ic:'🏠',lb:'Início'}],
};

const NAV_DEF = [{id:'home',ic:'🏠',lb:'Início'}];
