import React from 'react';
import {Tag} from '../tag/Tag.jsx';
export function PostCard({title,date,readTime,excerpt,categories=[],image,href='#',style}){
  const [hover,setHover]=React.useState(false);
  return <a href={href} onMouseEnter={()=>setHover(true)} onMouseLeave={()=>setHover(false)}
    style={{display:'block',textDecoration:'none',background:'var(--bg-2)',border:`1px solid ${hover?'var(--line-2)':'var(--line-1)'}`,borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',overflow:'hidden',transform:hover?'translateY(-2px)':'none',transition:'all var(--dur-base) var(--ease-out)',...style}}>
    {image&&<div style={{height:160,background:`url(${image}) center/cover`,borderBottom:'1px solid var(--line-1)',filter:hover?'none':'saturate(0.85)',transition:'filter var(--dur-base) var(--ease-out)'}}></div>}
    <div style={{padding:'20px 24px 22px'}}>
      <div style={{fontFamily:'var(--font-mono)',fontWeight:500,fontSize:'var(--text-xs)',letterSpacing:'var(--tracking-wide)',textTransform:'uppercase',color:'var(--fg-3)'}}>{date}{readTime?` · ${readTime}`:''}</div>
      <h3 style={{margin:'10px 0 0',fontFamily:'var(--font-display)',fontWeight:600,fontSize:'1.5rem',lineHeight:1.25,letterSpacing:'var(--tracking-tight)',color:hover?'var(--accent)':'var(--fg-1)',transition:'color var(--dur-fast) var(--ease-out)'}}>{title}</h3>
      {excerpt&&<p style={{margin:'10px 0 0',fontFamily:'var(--font-body)',fontSize:'1rem',lineHeight:1.6,color:'var(--fg-2)'}}>{excerpt}</p>}
      {categories.length>0&&<div style={{display:'flex',gap:8,marginTop:16}}>{categories.map(c=><Tag key={c} color="amber">{c}</Tag>)}</div>}
    </div>
  </a>;
}
