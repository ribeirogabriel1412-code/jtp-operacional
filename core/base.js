const { createClient } = window.supabase;

export const SUPABASE_URL = 'https://yxwxcxdegkvjvwchemsm.supabase.co';
// Publishable Key para auth + Anon Key JWT para operações RLS
export const SUPABASE_PK = 'sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV';
export const sb = createClient(SUPABASE_URL, SUPABASE_PK);

export const S = {user:null,perfil:null,tela:'painel',subtela:null,turno:'dia',garagens:[],frota:[],soltura210:[],filtroFrota:'todos',editVId:null,editSaidaId:null,editUserId:null,data210:null};

// Retorna o melhor token disponível: JWT do usuário logado ou Publishable Key
export function getAuthKey() { return S?.accessToken || SUPABASE_PK; }
