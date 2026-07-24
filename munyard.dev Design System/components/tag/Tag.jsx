import React from 'react';
export function Tag({children,color='neutral',active,onClick,style}){
  const map={neutral:['var(--fg-2)','transparent','var(--line-2)'],mint:['var(--accent)','var(--accent-dim)','transparent'],amber:['var(--amber)','var(--amber-dim)','transparent'],info:['var(--info)','var(--info-dim)','transparent']};
  const [fg,bg,bd]=map[color]||map.neutral;
  const [hover,setHover]=React.useState(false);
  return <span onClick={onClick} onMouseEnter={()=>setHover(true)} onMouseLeave={()=>setHover(false)}
    style={{display:'inline-flex',alignItems:'center',fontFamily:'var(--font-mono)',fontWeight:500,fontSize:'var(--text-xs)',letterSpacing:'0.03em',padding:'4px 12px',borderRadius:'var(--radius-full)',color:active?'var(--accent-ink)':fg,background:active?'var(--accent)':bg,border:`1px solid ${active?'transparent':bd}`,cursor:onClick?'pointer':'default',opacity:hover&&onClick?0.85:1,transition:'opacity var(--dur-fast) var(--ease-out)',...style}}>{children}</span>;
}
