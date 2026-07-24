function Header({onHome}){
  return <header style={{position:'sticky',top:0,zIndex:5,background:'rgba(11,14,20,0.7)',backdropFilter:'blur(14px)',WebkitBackdropFilter:'blur(14px)',borderBottom:'1px solid var(--line-1)'}}>
    <div style={{maxWidth:'var(--page-max)',margin:'0 auto',padding:'0 32px',height:64,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
      <a href="#" onClick={e=>{e.preventDefault();onHome();}} style={{fontFamily:'var(--font-mono)',fontWeight:600,fontSize:'1.0625rem',color:'var(--fg-1)',textDecoration:'none'}}>
        <span style={{color:'var(--accent)'}}>dylan@munyard.dev</span><span style={{color:'var(--fg-3)'}}>:~$</span><span className="blink" style={{color:'var(--fg-2)'}}>▊</span>
      </a>
      <nav style={{display:'flex',gap:28,alignItems:'center'}}>
        <a href="#" onClick={e=>{e.preventDefault();onHome();}} style={{fontFamily:'var(--font-display)',fontWeight:500,fontSize:'0.9375rem',color:'var(--fg-2)',textDecoration:'none'}}>Posts</a>
        <a href="#" onClick={e=>e.preventDefault()} style={{fontFamily:'var(--font-display)',fontWeight:500,fontSize:'0.9375rem',color:'var(--fg-2)',textDecoration:'none'}}>About</a>
        <a href="https://github.com/DylanMunyard" style={{fontFamily:'var(--font-mono)',fontWeight:500,fontSize:'0.875rem',color:'var(--fg-3)',textDecoration:'none'}}>github ↗</a>
      </nav>
    </div>
  </header>;
}
function Footer(){
  return <footer style={{borderTop:'1px solid var(--line-1)',marginTop:96}}>
    <div style={{maxWidth:'var(--page-max)',margin:'0 auto',padding:'32px',display:'flex',justifyContent:'space-between',alignItems:'baseline'}}>
      <span style={{fontFamily:'var(--font-mono)',fontSize:'var(--text-xs)',color:'var(--fg-3)'}}>© 2026 Dylan Munyard · munyard.dev</span>
      <span style={{fontFamily:'var(--font-mono)',fontSize:'var(--text-xs)',color:'var(--fg-3)'}}>Happy hacking</span>
    </div>
  </footer>;
}
Object.assign(window,{Header,Footer});
