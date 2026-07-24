function Home({onOpenPost}){
  const {PostCard,Tag}=window.MunyardDevDesignSystem_0136e3;
  const [filter,setFilter]=React.useState('all');
  const posts=[
    {id:'arch',title:'Running Arch Linux inside QEMU',date:'25 Feb 2024',readTime:'12 min read',cats:['virtualisation','linux'],excerpt:'Install Arch in a VM first, capture notes on the process, then if all goes well replace it as my host OS.',image:'../../assets/backgrounds/arch-qemu-header.jpg'},
    {id:'jenkins',title:'Deploying this blog with Jenkins on Kubernetes',date:'14 Mar 2024',readTime:'8 min read',cats:['kubernetes','ci'],excerpt:'Build agents as pods, a role binding for the blog namespace, and one kubectl apply.'},
    {id:'zsh',title:'Pimp your terminal: zsh, Oh My Posh and Nerd Fonts',date:'02 Apr 2024',readTime:'6 min read',cats:['terminal'],excerpt:'Look like a h4ck3r while getting genuinely useful git context in your prompt.'},
  ];
  const cats=['all','virtualisation','linux','kubernetes','ci','terminal'];
  const shown=posts.filter(p=>filter==='all'||p.cats.includes(filter));
  return <div>
    <section style={{maxWidth:'var(--page-max)',margin:'0 auto',padding:'96px 32px 64px'}}>
      <div style={{fontFamily:'var(--font-mono)',fontWeight:500,fontSize:'var(--text-xs)',letterSpacing:'var(--tracking-wide)',textTransform:'uppercase',color:'var(--amber)'}}>~ a lab notebook</div>
      <h1 style={{margin:'16px 0 0',fontFamily:'var(--font-display)',fontWeight:700,fontSize:'var(--text-4xl)',lineHeight:'var(--leading-tight)',letterSpacing:'var(--tracking-tight)',color:'var(--fg-1)',maxWidth:800}}>Notes on servers, VMs and the terminal.</h1>
      <p style={{margin:'20px 0 0',fontFamily:'var(--font-body)',fontSize:'var(--text-lg)',lineHeight:1.6,color:'var(--fg-2)',maxWidth:'56ch'}}>I'm Dylan. I write down what I break and how I fix it — Arch installs, Kubernetes deploys, web servers, shells.</p>
      <div style={{display:'flex',gap:10,flexWrap:'wrap',marginTop:36}}>
        {cats.map(c=><Tag key={c} active={filter===c} onClick={()=>setFilter(c)} color={filter===c?undefined:'neutral'}>{c}</Tag>)}
      </div>
    </section>
    <section style={{maxWidth:'var(--page-max)',margin:'0 auto',padding:'0 32px',display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(320px,1fr))',gap:24}}>
      {shown.map(p=><div key={p.id} onClick={e=>{e.preventDefault();onOpenPost(p.id);}}><PostCard title={p.title} date={p.date} readTime={p.readTime} excerpt={p.excerpt} categories={p.cats} image={p.image} href="#" /></div>)}
    </section>
  </div>;
}
window.Home=Home;
