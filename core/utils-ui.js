// ── Funções de interface (UI) ──────────────────────────────

function toast(msg,tipo='ok',dur=2200){
  const t=document.getElementById('toast');
  t.textContent=msg;
  t.className='show'+(tipo==='err'?' err':'');
  clearTimeout(t._t);
  t._t=setTimeout(()=>t.className='',dur);
}

function render(html){
  document.getElementById('content').innerHTML=html;
}

function setTela(t){
  S.tela=t;
  buildNav();
  render('<div class="loading"><div class="sp"></div></div>');
  TELAS[t]&&TELAS[t]();
}

function openSheet(ttl,html){
  document.getElementById('shttl').textContent=ttl;
  document.getElementById('shbody').innerHTML=html;
  document.getElementById('shov').classList.add('open');
}

function closeSheet(e){
  if(e===true||e.target===document.getElementById('shov'))
    document.getElementById('shov').classList.remove('open');
}

function buildNav(){
  const itens=NAV[cargo()]||NAV_DEF;
  document.getElementById('navbar').innerHTML=itens.map(n=>
    `<button class="nav-btn${S.tela===n.id?' active':''}" onclick="setTela('${n.id}')">
      <span class="nav-ic">${n.ic}</span>
      <span class="nav-lb">${n.lb}</span>
    </button>`
  ).join('');
}

function escHtml(v){
  return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
}

function moeda(v){
  return 'R$ '+parseFloat(v||0).toLocaleString('pt-BR',{minimumFractionDigits:2});
}
