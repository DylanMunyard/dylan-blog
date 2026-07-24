import React from 'react';
export function CodeBlock({code,lang,filename,highlightLines=[],style}){
  const [copied,setCopied]=React.useState(false);
  const lines=(code||'').replace(/\n$/,'').split('\n');
  const copy=()=>{try{navigator.clipboard.writeText(code);}catch(e){} setCopied(true);setTimeout(()=>setCopied(false),1500);};
  return <figure style={{margin:0,background:'var(--code-bg)',border:'1px solid var(--line-1)',borderRadius:'var(--radius-lg)',overflow:'hidden',boxShadow:'var(--shadow-card)',...style}}>
    <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',padding:'8px 16px',borderBottom:'1px solid var(--line-1)'}}>
      <span style={{fontFamily:'var(--font-mono)',fontSize:'var(--text-xs)',fontWeight:500,color:'var(--fg-3)'}}>{filename||lang||'shell'}</span>
      <button onClick={copy} style={{fontFamily:'var(--font-mono)',fontSize:'var(--text-xs)',fontWeight:500,color:copied?'var(--accent)':'var(--fg-3)',background:'none',border:'none',cursor:'pointer',padding:'2px 4px'}}>{copied?'copied':'copy'}</button>
    </div>
    <pre style={{margin:0,padding:'14px 0',overflowX:'auto'}}>
      {lines.map((l,i)=><div key={i} style={{display:'flex',background:highlightLines.includes(i+1)?'var(--code-line-hl)':'transparent'}}>
        <span style={{flex:'none',width:44,textAlign:'right',paddingRight:16,fontFamily:'var(--font-mono)',fontSize:'0.9375rem',lineHeight:1.7,color:'var(--code-gutter)',userSelect:'none'}}>{i+1}</span>
        <code style={{fontFamily:'var(--font-mono)',fontSize:'0.9375rem',lineHeight:1.7,color:'var(--code-fg)',whiteSpace:'pre',paddingRight:20,background:'none'}}>{l||' '}</code>
      </div>)}
    </pre>
  </figure>;
}
