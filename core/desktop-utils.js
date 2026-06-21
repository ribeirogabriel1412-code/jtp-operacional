// ── Helpers de cargo, data e UI (desktop) ─────────────────

// Cargo helpers
const cargo=()=>S.perfil?.cargo;
const isAdmin=()=>S.perfil?.is_admin;
const isLavador=()=>cargo()==='lavador';
function isEscalante(){return ['lider_operacional','gerente_garagem','diretoria'].includes(cargo())||isAdmin()}
function isLiderPatio(){return podeValidar('ferr-210')||podeExecutar('ferr-210');}
function isSupervisao(){return ['diretoria','gerente_garagem','gerente_operacional','coordenador','supervisor','lider_operacional','lider_pcm','assistente_pcm'].includes(cargo())||isAdmin()}
function isLavadorOuPatio(){return ['lavador','lider_patio','gerente_garagem','diretoria'].includes(cargo())||isAdmin()}

// Utilitários de data/hora operacional
const TZ_OPERACIONAL_PADRAO='America/Manaus';
function opNormTxt(v){return String(v||'').normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase();}
function opTimezone(gid){
  const gidRef=gid||(typeof getGid==='function'?getGid():null);
  const g=(S.garagens||[]).find(x=>x.id===gidRef);
  const txt=opNormTxt(`${g?.nome||''} ${g?.cidade||''} ${g?.sigla||''}`);
  return txt.includes('braganca')?'America/Sao_Paulo':TZ_OPERACIONAL_PADRAO;
}
function opParts(date=new Date(),tz=opTimezone()){
  const parts=new Intl.DateTimeFormat('en-CA',{timeZone:tz,year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:false}).formatToParts(date);
  const o={};parts.forEach(p=>{if(p.type!=='literal')o[p.type]=p.value;});
  if(o.hour==='24')o.hour='00';
  return {y:+o.year,m:+o.month,d:+o.day,H:+o.hour,M:+o.minute,S:+o.second};
}
function opISODate(date=new Date(),tz=opTimezone()){const p=opParts(date,tz);return `${p.y}-${String(p.m).padStart(2,'0')}-${String(p.d).padStart(2,'0')}`;}
function opAddDays(iso,days){const [y,m,d]=String(iso).split('-').map(Number);const dt=new Date(Date.UTC(y,m-1,d+Number(days||0),12));return dt.toISOString().slice(0,10);}
function opDateTimeISO(data,hora,tz=opTimezone()){
  const [y,m,d]=String(data).split('-').map(Number),[H,M]=String(hora||'00:00').split(':').map(Number);
  let utc=Date.UTC(y,m-1,d,H||0,M||0,0);
  for(let i=0;i<3;i++){
    const p=opParts(new Date(utc),tz);
    const desejado=Date.UTC(y,m-1,d,H||0,M||0,0);
    const atual=Date.UTC(p.y,p.m-1,p.d,p.H,p.M,0);
    utc+=desejado-atual;
  }
  return new Date(utc).toISOString();
}
function turnoOperacionalAtual(tz=opTimezone()){const p=opParts(new Date(),tz),min=p.H*60+p.M;return (min>=20*60||min<4*60+20)?'noite':'dia';}
function dataOperacionalAtual(turno=turnoOperacionalAtual(),tz=opTimezone()){
  const data=opISODate(new Date(),tz),p=opParts(new Date(),tz),min=p.H*60+p.M;
  return turno==='noite'&&min<4*60+20?opAddDays(data,-1):data;
}
function janelaOperacional(turno=turnoOperacionalAtual(),dataRef=dataOperacionalAtual(turno),tz=opTimezone()){
  const defs={dia:{ini:'08:00',fim:'18:00',label:'Dia 08:00-18:00'},noite:{ini:'20:00',fim:'04:20',label:'Noite 20:00-04:20'},dia_completo:{ini:'08:00',fim:'08:00',label:'Dia completo 08:00-08:00',diaAnterior:true}};
  const d=defs[turno]||defs.dia;
  const dataIni=d.diaAnterior?opAddDays(dataRef,-1):dataRef;
  const dataFim=(d.fim<=d.ini)?opAddDays(dataIni,1):dataIni;
  const ini=opDateTimeISO(dataIni,d.ini,tz),fim=opDateTimeISO(dataFim,d.fim,tz);
  return {turno,dataRef,dataIni,dataFim,horaIni:d.ini,horaFim:d.fim,ini,fim,dtIni:new Date(ini),dtFim:new Date(fim),label:d.label};
}
// Ciclo da frota: 07:20 do dia D até 07:20 do dia D+1
function dataFrotaAtual(tz=opTimezone()){
  const p=opParts(new Date(),tz),min=p.H*60+p.M;
  return min<7*60+20?opAddDays(opISODate(new Date(),tz),-1):opISODate(new Date(),tz);
}
function janelaFrota(dataRef=dataFrotaAtual(),tz=opTimezone()){
  const ini=opDateTimeISO(dataRef,'07:20',tz),fim=opDateTimeISO(opAddDays(dataRef,1),'07:20',tz);
  return {dataRef,ini,fim,dtIni:new Date(ini),dtFim:new Date(fim)};
}

// UI helpers
function hoje(){return opISODate()}
function hojeF(){return new Date().toLocaleDateString('pt-BR',{weekday:'long',day:'numeric',month:'long',timeZone:opTimezone()})}
function fmt(n){return Number(n||0).toLocaleString('pt-BR')}
function badge(s){const c=ST_CFG[s]||{l:s,cls:''};return`<span class="badge ${c.cls}">${c.l}</span>`}
function toast(msg,type='ok'){const el=document.createElement('div');el.className=`toast ${type}`;el.innerHTML=`<span>${type==='ok'?'✅':'❌'}</span> ${msg}`;document.body.appendChild(el);setTimeout(()=>el.remove(),3500)}
function setMain(html){const m=document.getElementById('main');m.style.animation='none';m.offsetHeight;m.style.animation='fadeIn .25s ease both';m.innerHTML=html}
function closeM(id){document.getElementById(id).style.display='none'}
function secTitle(icon,text,action=''){return`<div class="sec-title"><span style="font-size:15px">${icon}</span><span class="st-text">${text}</span><div class="st-line"></div>${action}</div>`}
function kpi(label,val,meta,unit='%',inv=false,dec=1){
  const n=parseFloat(val);let st='neu',stH='';
  if(meta!==undefined){st=inv?(n<=meta?'ok':'nok'):(n>=meta?'ok':'nok');stH=`<div class="kpi-meta ${st}">${st==='ok'?'✓ OK':'✗ NOK'} — Meta: ${meta}${unit}</div>`}
  const dsp=typeof val==='number'?val.toFixed(dec):val??'—';
  return`<div class="kpi ${st}"><div class="kpi-label">${label}</div><div class="kpi-val">${dsp}<span style="font-size:12px;color:var(--text4);font-weight:400"> ${unit}</span></div>${stH}</div>`
}
