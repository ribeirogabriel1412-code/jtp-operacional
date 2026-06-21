// ── Utilitários mobile — datas, preventiva, valetamento ───

function proximoSabadoISO(base=new Date()){
  const d=new Date(base.getFullYear(),base.getMonth(),base.getDate());
  const faltam=(6-d.getDay()+7)%7;
  d.setDate(d.getDate()+faltam);
  return d.toISOString().slice(0,10);
}

async function resolverDataValetMobile(gid,dataPreferida,usuarioEscolheu=false){
  if(usuarioEscolheu) return dataPreferida||proximoSabadoISO();
  const alvo=dataPreferida||proximoSabadoISO();
  try{
    const atual=await sb.from('requisicoes_compra')
      .select('data').eq('garagem_id',gid).is('ocorrencia_id',null)
      .neq('status','cancelado').not('data','is',null).eq('data',alvo).limit(1);
    if((atual.data||[]).length){_valetMobData=alvo;return alvo;}
    const ult=await sb.from('requisicoes_compra')
      .select('data').eq('garagem_id',gid).is('ocorrencia_id',null)
      .neq('status','cancelado').not('data','is',null)
      .lte('data',alvo).order('data',{ascending:false}).limit(1);
    const encontrada=ult.data?.[0]?.data;
    if(encontrada){_valetMobData=encontrada;return encontrada;}
  }catch(e){console.warn('[VALET DATA]',e);}
  _valetMobData=alvo;
  return alvo;
}

function mobParseISO(iso){
  const [y,m,d]=String(iso||'').split('-').map(Number);
  return new Date(y||new Date().getFullYear(),(m||1)-1,d||1);
}

function mobISO(d){
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}

function mobDiaMes(iso){
  const d=mobParseISO(iso);
  return `${String(d.getDate()).padStart(2,'0')}/${String(d.getMonth()+1).padStart(2,'0')}`;
}

function mobPrefKey(p){return String(p||'').replace(/\D/g,'').replace(/^0+/,'');}

function mobPrevHistKey(){
  let gid='geral';
  try{gid=getGid()||'geral';}catch(e){}
  return `jtp_prev_historicos_v1:${gid}`;
}

function mobPrevHistoricos(){
  try{
    const h=JSON.parse(localStorage.getItem(mobPrevHistKey())||'{}')||{};
    return {semanas:Array.isArray(h.semanas)?h.semanas:[],importacoes:Array.isArray(h.importacoes)?h.importacoes:[]};
  }catch(e){return {semanas:[],importacoes:[]};}
}

function mobSemanaLabel(s){return `${s?.inicioBR||'--/--'} a ${s?.fimBR||'--/--'}`;}

function mobSemanaDaData(data){
  const semanas=mobPrevHistoricos().semanas||[];
  return semanas.find(s=>s.inicio<=data&&s.fim>=data)||semanas[0]||null;
}

function mobDataValetDaSemana(semana){
  if(!semana?.inicio)return proximoSabadoISO();
  const d=mobParseISO(semana.inicio);
  d.setDate(d.getDate()-9);
  return mobISO(d);
}

function mobSemanaPeriodo(data){
  const d=mobParseISO(data);
  const ini=new Date(d);
  ini.setDate(d.getDate()-((d.getDay()+6)%7));
  const fim=new Date(ini);
  fim.setDate(ini.getDate()+4);
  return {inicio:mobISO(ini),fim:mobISO(fim),inicioBR:mobDiaMes(mobISO(ini)),fimBR:mobDiaMes(mobISO(fim))};
}

function mobDiaSemanaIdx(label){
  const s=String(label||'').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g,'');
  if(s.includes('segunda'))return 1;
  if(s.includes('terca'))return 2;
  if(s.includes('quarta'))return 3;
  if(s.includes('quinta'))return 4;
  if(s.includes('sexta'))return 5;
  if(s.includes('sabado'))return 6;
  if(s.includes('domingo'))return 0;
  return null;
}

function mobNormalizarData(v,ref=hoje()){
  if(!v)return '';
  if(v instanceof Date)return mobISO(v);
  const s=String(v).trim();
  const iso=(s.match(/\d{4}-\d{2}-\d{2}/)||[])[0];
  if(iso)return iso;
  const br=s.match(/(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?/);
  if(br){
    const y=br[3]?String(br[3]).padStart(4,'20'):String(ref).slice(0,4);
    return `${y}-${String(br[2]).padStart(2,'0')}-${String(br[1]).padStart(2,'0')}`;
  }
  return s.slice(0,10);
}

function mobProgData(row){
  return mobNormalizarData(row?.data||row?.iso||row?.data_programada||row?.data_prevista||row?.data_execucao||row?.data_os||row?.programado_para||row?.data_programacao||row?.dt||row?.created_at);
}

function mobProgPrefixo(row){
  return row?.prefixo||row?.veiculo||row?.carro||row?.prefixo_veiculo||row?.codigo_veiculo||row?.codigo||row?.placa_prefixo||'';
}

function mobProgTipo(row){
  const bruto=String(row?.tipo||row?.tipo_preventiva||row?.tipo_os||row?.categoria||row?.plano_tipo||row?.tipo_manutencao||'').toLowerCase();
  const texto=`${bruto} ${mobProgServ(row)}`.toLowerCase();
  if(/pesada|preventiva_pesada|plano\s*002|\b002\b/.test(texto))return 'pesada';
  if(/óleo|oleo/.test(texto))return 'oleo';
  if(/leve/.test(texto))return 'leve';
  return bruto;
}

function mobProgServ(row){
  return String(row?.servicos||row?.servico||row?.descricao||row?.plano_nome||row?.planoNome||row?.plano||row?.observacao||row?.obs||row?.itens_servico||'');
}

function mobDiaProgramadoReq(r){
  return (String(r?.justificativa||'').match(/Programado preventiva:\s*(\d{4}-\d{2}-\d{2})/i)||[])[1]||'';
}

function mobExpandProgRows(rows){
  const out=[];
  const push=(r,base={})=>{
    if(!r)return;
    if(Array.isArray(r)){r.forEach(x=>push(x,base));return;}
    if(typeof r==='string'){try{push(JSON.parse(r),base);}catch(e){}return;}
    if(typeof r!=='object')return;
    const filhos=r.itens||r.programacao||r.programacoes||r.escala||r.dados||r.carros||null;
    if(Array.isArray(filhos)){filhos.forEach(x=>push(x,{...base,...r}));}
    else out.push({...base,...r});
  };
  (rows||[]).forEach(r=>push(r));
  return out;
}

function mobProgramaFromSemanaLocal(data){
  const semana=mobSemanaDaData(data);
  if(!semana)return {semana:null,itens:[]};
  return {semana,itens:(semana.itens||[]).filter(i=>i.prefixo&&i.iso===data).map(i=>({
    prefixo:i.prefixo,iso:i.iso,tipo:i.tipo,servicos:i.servicos||i.planoNome||'',origem:'local'
  }))};
}

async function mobBuscarProgramacaoPreventivaDia(gid,data){
  const periodo=mobSemanaPeriodo(data);
  const diaIdx=mobParseISO(data).getDay();
  let itens=[];
  try{
    const marc=await sb.from('requisicoes_compra')
      .select('*').eq('garagem_id',gid).eq('data',data)
      .neq('status','cancelado').order('prefixo',{ascending:true});
    const rows=(marc.data||[]).filter(r=>r.status==='programado_preventiva'||r.cod_sap==='__PROG_PREV__'||String(r.peca||'').includes('Programação preventiva'));
    if(rows.length){
      const vistos=new Set();
      itens=rows.filter(r=>{
        const k=mobPrefKey(r.prefixo);
        if(!k||vistos.has(k))return false;
        vistos.add(k);return true;
      }).map(r=>({
        raw:r,prefixo:r.prefixo,iso:data,tipo:'pesada',
        servicos:String(r.justificativa||'').replace(/Programação preventiva pesada\s*·?\s*/i,''),
        origem:'marcador'
      }));
      return {semana:{inicio:periodo.inicio,fim:periodo.fim,inicioBR:periodo.inicioBR,fimBR:periodo.fimBR},itens};
    }
  }catch(e){console.warn('[PREV MARCADORES]',e);}
  try{
    let res=await sb.from('programacao_preventiva').select('*').eq('garagem_id',gid).limit(1200);
    let rows=res.data||[];
    if(!rows.length){
      res=await sb.from('programacao_preventiva').select('*').limit(1200);
      rows=(res.data||[]).filter(r=>!r.garagem_id||r.garagem_id===gid||r.garagem===gid);
    }
    let exp=mobExpandProgRows(rows).map(r=>{
      let iso=mobProgData(r);
      const idxLabel=mobDiaSemanaIdx(r.dia||r.label||r.dia_semana||r.weekday);
      if((!iso||iso===String(r.dia||'').slice(0,10))&&idxLabel!==null){
        const d=mobParseISO(periodo.inicio);
        d.setDate(d.getDate()+(idxLabel===0?6:idxLabel-1));
        iso=mobISO(d);
      }
      return {raw:r,prefixo:mobProgPrefixo(r),iso,tipo:mobProgTipo(r),servicos:mobProgServ(r),
        criado_em:r.criado_em||r.created_at||r.atualizado_em||r.updated_at||'',
        semana_inicio:r.semana_inicio||r.inicio||periodo.inicio,
        semana_fim:r.semana_fim||r.fim||periodo.fim,origem:'banco'};
    }).filter(i=>i.prefixo&&i.iso>=periodo.inicio&&i.iso<=periodo.fim);
    if(exp.length){
      const loteMaisRecente=exp.map(i=>String(i.criado_em||'')).sort().pop()||'';
      const dataLote=loteMaisRecente?loteMaisRecente.slice(0,16):'';
      const recentes=dataLote?exp.filter(i=>String(i.criado_em||'').slice(0,16)===dataLote):exp;
      itens=recentes.filter(i=>i.iso===data);
    }
  }catch(e){console.warn('[PREV DIA BANCO]',e);}
  if(!itens.length){
    const loc=mobProgramaFromSemanaLocal(data);
    itens=loc.itens;
    if(!itens.length&&loc.semana?.itens?.length){
      itens=(loc.semana.itens||[]).filter(i=>i.prefixo&&mobDiaSemanaIdx(i.dia||i.label)===diaIdx)
        .map(i=>({...i,iso:data,servicos:i.servicos||i.planoNome||'',origem:'local-dia'}));
    }
  }
  return {semana:{inicio:periodo.inicio,fim:periodo.fim,inicioBR:periodo.inicioBR,fimBR:periodo.fimBR},itens};
}

async function mobBuscarReqsValetParaDia(gid,data,programados){
  const periodo=mobSemanaPeriodo(data);
  const valet=new Date(mobParseISO(periodo.inicio));
  valet.setDate(valet.getDate()-9);
  const datas=[mobISO(valet),_valetMobData,await resolverDataValetMobile(gid,_valetMobData||proximoSabadoISO(),!!_valetMobData)].filter(Boolean);
  for(const dt of [...new Set(datas)]){
    try{
      const res=await sb.from('requisicoes_compra').select('*').eq('garagem_id',gid).eq('data',dt)
        .neq('status','cancelado').neq('status','programado_preventiva')
        .order('prefixo',{ascending:true}).order('criado_em',{ascending:true});
      const rows=(res.data||[]).filter(r=>r.cod_sap!=='__PROG_PREV__'&&!String(r.peca||'').includes('Programação preventiva'));
      if(rows.length){
        const programKeys=new Set((programados||[]).map(p=>mobPrefKey(p.prefixo)));
        const bate=rows.some(r=>programKeys.has(mobPrefKey(r.prefixo)));
        if(bate||!programKeys.size)return {dataValet:dt,rows};
      }
    }catch(e){console.warn('[REQ VALET DIA]',e);}
  }
  try{
    const ini=new Date(mobParseISO(periodo.inicio));ini.setDate(ini.getDate()-21);
    const fim=new Date(mobParseISO(periodo.fim));fim.setDate(fim.getDate()+1);
    const res=await sb.from('requisicoes_compra').select('*').eq('garagem_id',gid)
      .gte('data',mobISO(ini)).lte('data',mobISO(fim))
      .neq('status','cancelado').neq('status','programado_preventiva')
      .order('data',{ascending:false}).order('prefixo',{ascending:true});
    const rows=(res.data||[]).filter(r=>r.cod_sap!=='__PROG_PREV__'&&!String(r.peca||'').includes('Programação preventiva'));
    const programKeys=new Set((programados||[]).map(p=>mobPrefKey(p.prefixo)));
    const candidatos=rows.filter(r=>programKeys.has(mobPrefKey(r.prefixo)));
    if(candidatos.length){
      const porData={};
      candidatos.forEach(r=>{if(!porData[r.data])porData[r.data]=[];porData[r.data].push(r);});
      const best=Object.entries(porData).sort((a,b)=>b[1].length-a[1].length||String(b[0]).localeCompare(String(a[0])))[0];
      if(best)return {dataValet:best[0],rows:best[1]};
    }
    const tagueados=rows.filter(r=>mobDiaProgramadoReq(r)===data);
    if(tagueados.length){
      const dataVal=tagueados[0].data||datas[0]||proximoSabadoISO();
      return {dataValet:dataVal,rows:tagueados};
    }
  }catch(e){console.warn('[REQ VALET RANGE]',e);}
  return {dataValet:datas[0]||proximoSabadoISO(),rows:[]};
}
