// ── Sistema de permissões 3 níveis (desktop) ─────────────
// Persiste no localStorage — admin pode sobrescrever
function getPermsFerr(){
  try{
    const salvo=JSON.parse(localStorage.getItem('jtp_perms_ferr3')||'null');
    if(!salvo)return null;
    let mudou=false;
    FERRAMENTAS_DEF.forEach(f=>{
      if(!salvo[f.id]){
        salvo[f.id]={executa:[...(f.executa||[])],valida:[...(f.valida||[])],visualiza:[...(f.visualiza||[])]};
        mudou=true;
      }else{
        PAPEIS.forEach(papel=>{
          if(!Array.isArray(salvo[f.id][papel])){
            salvo[f.id][papel]=[...(f[papel]||[])];
            mudou=true;
          }
        });
        if(f.id==='ferr-21'){
          ['supervisor','coordenador','gerente_operacional'].forEach(c=>{
            PAPEIS.forEach(p=>{salvo[f.id][p]=(salvo[f.id][p]||[]).filter(x=>x!==c);});
            salvo[f.id].executa=[...new Set([...(salvo[f.id].executa||[]),c])];
          });
          mudou=true;
        }
      }
    });
    if(mudou)setPermsFerr(salvo);
    return salvo;
  }catch{return null;}
}
function setPermsFerr(perms){localStorage.setItem('jtp_perms_ferr3',JSON.stringify(perms));}

// Retorna o papel do cargo na ferramenta: 'executa' | 'valida' | 'visualiza' | null
function papelFerr(ferrId, cargoOverride){
  const c=cargoOverride||S.perfil?.cargo;
  if(ferrId==='ferr-21'&&['supervisor','coordenador','gerente_operacional'].includes(c)) return 'executa';
  if(S.perfil?.is_admin&&!cargoOverride) return 'executa';
  const perms=getPermsFerr();
  const ferr=FERRAMENTAS_DEF.find(f=>f.id===ferrId);
  if(!ferr) return null;
  for(const papel of PAPEIS){
    const lista=perms?.[ferrId]?.[papel]??ferr[papel];
    if(lista.includes(c)) return papel;
  }
  return null;
}

function podeExecutar(ferrId){const p=papelFerr(ferrId);return p==='executa';}
function podeValidar(ferrId){const p=papelFerr(ferrId);return p==='executa'||p==='valida';}
function podeVisualizar(ferrId){return papelFerr(ferrId)!==null;}
function temAcessoFerr(ferrId){return podeVisualizar(ferrId);}
