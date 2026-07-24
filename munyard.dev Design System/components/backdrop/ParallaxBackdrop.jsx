import React from 'react';
export function ParallaxBackdrop({image,dim=0.55,shift=16,children,style}){
  const ref=React.useRef(null);
  const [pos,setPos]=React.useState({x:0,y:0});
  React.useEffect(()=>{
    const onMove=e=>{
      const w=window.innerWidth,h=window.innerHeight;
      setPos({x:((e.clientX/w)-0.5)*2,y:((e.clientY/h)-0.5)*2});
    };
    window.addEventListener('mousemove',onMove);
    return ()=>window.removeEventListener('mousemove',onMove);
  },[]);
  return <>
    <div ref={ref} aria-hidden="true" style={{position:'fixed',inset:-shift*2,zIndex:0,background:`url(${image}) center/cover no-repeat var(--bg-0)`,transform:`translate(${-pos.x*shift}px,${-pos.y*shift}px)`,transition:'transform 400ms var(--ease-out)',willChange:'transform',...style}}>
      <div style={{position:'absolute',inset:0,background:`rgba(7,9,14,${dim})`}}></div>
      <div style={{position:'absolute',inset:0,background:'linear-gradient(180deg,rgba(11,14,20,0.2) 0%,rgba(11,14,20,0.65) 100%)'}}></div>
    </div>
    <div style={{position:'relative',zIndex:1}}>{children}</div>
  </>;
}
