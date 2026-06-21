// ── Autenticação — login, init, logout ────────────────────

async function doLogin(){
  const input=document.getElementById('le').value.trim();
  const senha=document.getElementById('ls').value;
  const err=document.getElementById('lerr');
  if(!input||!senha){err.textContent='Preencha matrícula/e-mail e senha.';return;}
  err.textContent='Entrando...';

  let email=input;
  if(!input.includes('@')){
    const{data:perfil}=await sb.from('perfis').select('email').eq('matricula',input).single();
    if(!perfil?.email){
      err.textContent='Matrícula não encontrada. Verifique com o administrador.';
      return;
    }
    email=perfil.email;
  }

  const{data,error}=await sb.auth.signInWithPassword({email,password:senha});
  if(error){err.textContent='Matrícula/e-mail ou senha incorretos.';return;}
  err.textContent='';
  S.user=data.user;
  await init();
}

async function init(){
  try{
    const[{data:p},{data:g}]=await Promise.all([
      sb.from('perfis').select('*').eq('id',S.user.id).single(),
      sb.from('garagens').select('*').order('nome'),
    ]);
    S.perfil=p;S.garagens=g||[];
    S.turno=turnoOperacionalAtual(opTimezone(p?.garagem_id));
    if(typeof _r33Turno!=='undefined'){
      _r33Turno=S.turno;
      _r33Data=dataOperacionalAtual(_r33Turno,opTimezone(p?.garagem_id));
    }
    const gar=S.garagens.find(x=>x.id===p?.garagem_id);
    document.getElementById('tbn').textContent=p?.nome?.split(' ')[0]||'—';
    document.getElementById('tbc').textContent=CARGOS[p?.cargo]||p?.cargo||'—';
    document.getElementById('tbg').textContent=(gar?.nome||'—').replace('JTP ','').replace('Garagem ','').split('—')[0].trim();
    document.getElementById('login').style.display='none';
    document.getElementById('app').style.display='flex';
    buildNav();
    setTela(TELA_INICIO[cargo()]||'home');
  }catch(err){
    console.error('Init error:',err);
    const lerr=document.getElementById('lerr');
    if(lerr) lerr.textContent='Erro: '+err.message;
    const loginEl=document.getElementById('login');
    const appEl=document.getElementById('app');
    if(loginEl) loginEl.style.display='flex';
    if(appEl) appEl.style.display='none';
    setTimeout(()=>toast('Erro ao carregar perfil. Tente novamente.','err'),500);
  }
}

async function doLogout(){
  await sb.auth.signOut();
  location.reload();
}
