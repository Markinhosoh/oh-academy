// Ponte entre o material e o portal OH! academy. Dentro do portal: progresso por usuário,
// XP ao concluir, podcast vindo da pasta privada do Supabase e registro de uso para o admin.
// Aberto fora do portal, o material funciona sozinho como antes.
(function(){
  let P=null;try{P=window.parent!==window?window.parent.OHPonte||null:null}catch(e){}
  const m=location.pathname.match(/\/m(\d)\/material-(\d+)\.html$/);
  const a=document.getElementById("audio"),f=a&&a.dataset.src;
  if(!P||!m){if(f)a.src=f;return}
  const mod=+m[1],mat=+m[2];
  window.OHPFX=P.uid+"-";
  const ev=(tipo,dados)=>P.evento(tipo,mod,mat,dados||null);

  // podcast: o MP3 fica na pasta privada do Supabase (mN/arquivo.mp3) e entra com link temporário
  if(a){P.audioUrl(`m${mod}/${f}`).then(u=>{
      if(u){a.src=u;a.load();return}
      const n=document.createElement("p");n.style.cssText="font-weight:700;background:rgba(0,0,0,.18);border-radius:12px;padding:10px 14px";
      n.textContent="O áudio deste material ainda está chegando no portal. Volte daqui a pouco pra ouvir.";
      (a.closest(".pod")||a.parentNode).appendChild(n)});
    let marco=0;
    a.addEventListener("play",()=>ev("play_audio"));
    a.addEventListener("timeupdate",()=>{if(!a.duration)return;const p=Math.floor(a.currentTime/a.duration*4)*25;if(p>marco){marco=p;ev("audio",{pct:p})}});
    a.addEventListener("ended",()=>{if(marco<100){marco=100;ev("audio",{pct:100})}})}

  // cliques nos visuais (cards, abas, simuladores, situações de treino)
  document.addEventListener("click",e=>{const el=e.target.closest("button,[role=tab],.flip,a");
    if(!el||el.closest(".player,.speed,.check"))return;
    ev("clique_visual",{item:(el.getAttribute("aria-label")||el.textContent||"").replace(/\s+/g," ").trim().slice(0,60)})},true);

  // concluído quando as 3 etapas do topo ficam marcadas
  let avisou=false;
  const checar=()=>{const li=[...document.querySelectorAll(".steps li")];
    if(!avisou&&li.length&&li.every(x=>x.classList.contains("done"))){avisou=true;P.concluir(mod,mat)}};
  addEventListener("DOMContentLoaded",()=>{
    const s=document.querySelector(".steps");if(s)new MutationObserver(checar).observe(s,{subtree:true,attributes:true,attributeFilter:["class"]});
    // já concluído em outro aparelho: deixa tudo marcado
    if(P.feito(mod,mat)){avisou=true;document.querySelectorAll(".check input").forEach(c=>{if(!c.checked)c.click()})}
    checar()});
})();
