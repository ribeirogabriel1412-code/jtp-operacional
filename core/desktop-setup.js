// ── Supabase + Estado global (desktop) ────────────────────
const {createClient}=supabase;
const SUPABASE_URL='https://yxwxcxdegkvjvwchemsm.supabase.co';
const SUPABASE_PK='sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV';
const sb=createClient(SUPABASE_URL,SUPABASE_PK);
const S={user:null,perfil:null,tela:'painel',subtela:null,turno:'dia',garagens:[],frota:[],soltura210:[],filtroFrota:'todos',editVId:null,editSaidaId:null,editUserId:null,data210:null};

if(window.pdfjsLib&&pdfjsLib.GlobalWorkerOptions){
  pdfjsLib.GlobalWorkerOptions.workerSrc='https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
}
