// Verificar se Supabase carregou
if(typeof supabase === 'undefined'){
  document.body.innerHTML='<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;padding:24px;text-align:center;background:#1F2937;color:#F9FAFB"><div style="font-size:48px;margin-bottom:16px">⚠️</div><div style="font-size:18px;font-weight:700;margin-bottom:8px">Sem conexão</div><div style="font-size:14px;color:#9CA3AF;margin-bottom:24px">Verifique sua internet e tente novamente.</div><button onclick="location.reload()" style="background:#2563EB;color:#fff;border:none;border-radius:12px;padding:14px 28px;font-size:16px;font-weight:700;cursor:pointer">🔄 Tentar Novamente</button></div>';
  throw new Error('Supabase não carregou');
}
const {createClient}=supabase;
const sb=createClient('https://yxwxcxdegkvjvwchemsm.supabase.co','sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV');
const S={user:null,perfil:null,garagens:[],tela:'home',turno:'dia'};
