import React from 'react';
export function Callout({kind='tip',title,children,style}){
  const map={tip:['var(--accent)','var(--accent-dim)','TIP'],info:['var(--info)','var(--info-dim)','NOTE'],warning:['var(--warn)','var(--warn-dim)','WARNING'],danger:['var(--danger)','var(--danger-dim)','DANGER']};
  const [fg,bg,label]=map[kind]||map.tip;
  return <aside style={{background:'var(--bg-2)',border:'1px solid var(--line-1)',borderRadius:'var(--radius-lg)',overflow:'hidden',...style}}>
    <div style={{display:'flex',alignItems:'center',gap:10,padding:'10px 18px',background:bg}}>
      <span style={{fontFamily:'var(--font-mono)',fontWeight:600,fontSize:'var(--text-xs)',letterSpacing:'var(--tracking-wide)',color:fg}}>{title?`${label} — ${title}`:label}</span>
    </div>
    <div style={{padding:'14px 18px',fontFamily:'var(--font-body)',fontSize:'1.0625rem',lineHeight:1.65,color:'var(--fg-2)'}}>{children}</div>
  </aside>;
}
