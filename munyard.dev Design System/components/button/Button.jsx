import React from 'react';
export function Button({variant='primary',size='md',children,href,disabled,onClick,style}){
  const pad=size==='sm'?'8px 14px':size==='lg'?'14px 24px':'11px 18px';
  const fs=size==='sm'?'0.875rem':size==='lg'?'1.0625rem':'0.9375rem';
  const base={display:'inline-flex',alignItems:'center',gap:8,fontFamily:'var(--font-display)',fontWeight:600,fontSize:fs,lineHeight:1,padding:pad,borderRadius:'var(--radius-md)',border:'1px solid transparent',cursor:disabled?'not-allowed':'pointer',opacity:disabled?0.45:1,textDecoration:'none',transition:'all var(--dur-fast) var(--ease-out)',userSelect:'none'};
  const variants={
    primary:{background:'var(--accent)',color:'var(--accent-ink)'},
    secondary:{background:'var(--bg-3)',color:'var(--fg-1)',borderColor:'var(--line-2)'},
    ghost:{background:'transparent',color:'var(--fg-2)'},
    danger:{background:'var(--danger-dim)',color:'var(--danger)',borderColor:'transparent'},
  };
  const [hover,setHover]=React.useState(false);
  const [press,setPress]=React.useState(false);
  const hoverStyles={primary:{background:'var(--accent-strong)'},secondary:{background:'var(--bg-3)',borderColor:'var(--line-2)',color:'var(--accent)'},ghost:{color:'var(--fg-1)',background:'var(--bg-2)'},danger:{background:'rgba(253,164,175,0.2)'}};
  const s={...base,...variants[variant],...(hover&&!disabled?hoverStyles[variant]:{}),transform:press&&!disabled?'scale(0.98)':'none',...style};
  const Tag=href?'a':'button';
  return <Tag href={href} disabled={disabled} onClick={disabled?undefined:onClick} style={s}
    onMouseEnter={()=>setHover(true)} onMouseLeave={()=>{setHover(false);setPress(false);}}
    onMouseDown={()=>setPress(true)} onMouseUp={()=>setPress(false)}>{children}</Tag>;
}
