// ── Utilitários de data e timezone ────────────────────────

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

function opISODate(date=new Date(),tz=opTimezone()){
  const p=opParts(date,tz);
  return `${p.y}-${String(p.m).padStart(2,'0')}-${String(p.d).padStart(2,'0')}`;
}

function opAddDays(iso,days){
  const [y,m,d]=String(iso).split('-').map(Number);
  const dt=new Date(Date.UTC(y,m-1,d+Number(days||0),12));
  return dt.toISOString().slice(0,10);
}

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

function turnoOperacionalAtual(tz=opTimezone()){
  const p=opParts(new Date(),tz),min=p.H*60+p.M;
  return (min>=20*60||min<4*60+20)?'noite':'dia';
}

function dataOperacionalAtual(turno=turnoOperacionalAtual(),tz=opTimezone()){
  const data=opISODate(new Date(),tz),p=opParts(new Date(),tz),min=p.H*60+p.M;
  return turno==='noite'&&min<4*60+20?opAddDays(data,-1):data;
}

function janelaOperacional(turno=turnoOperacionalAtual(),dataRef=dataOperacionalAtual(turno),tz=opTimezone()){
  const defs={
    dia:          {ini:'08:00',fim:'18:00',label:'Dia 08:00-18:00'},
    noite:        {ini:'20:00',fim:'04:20',label:'Noite 20:00-04:20'},
    dia_completo: {ini:'08:00',fim:'08:00',label:'Dia completo 08:00-08:00',diaAnterior:true}
  };
  const d=defs[turno]||defs.dia;
  const dataIni=d.diaAnterior?opAddDays(dataRef,-1):dataRef;
  const dataFim=(d.fim<=d.ini)?opAddDays(dataIni,1):dataIni;
  const ini=opDateTimeISO(dataIni,d.ini,tz),fim=opDateTimeISO(dataFim,d.fim,tz);
  return {turno,dataRef,dataIni,dataFim,horaIni:d.ini,horaFim:d.fim,ini,fim,dtIni:new Date(ini),dtFim:new Date(fim),label:d.label};
}

function hoje(){return opISODate();}

function getGid(){return S.perfil?.garagem_id||S.garagens?.[0]?.id;}

function fluxoCdMobileHabilitado(gid=getGid()){
  const g=S.garagens?.find(x=>x.id===gid);
  const nome=String(`${g?.nome||''} ${g?.cidade||''} ${g?.sigla||''}`)
    .normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase();
  return nome.includes('braganca');
}

function cargo(){return S.perfil?.cargo;}
