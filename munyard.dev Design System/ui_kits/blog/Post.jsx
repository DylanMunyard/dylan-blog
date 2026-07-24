function Post({onHome}){
  const {ParallaxBackdrop,Callout,CodeBlock,Tag,Button}=window.MunyardDevDesignSystem_0136e3;
  const scrim={background:'var(--scrim-content)',backdropFilter:'blur(var(--scrim-blur))',WebkitBackdropFilter:'blur(var(--scrim-blur))',border:'1px solid var(--line-1)',borderRadius:'var(--radius-lg)'};
  const h2={margin:'56px 0 0',fontFamily:'var(--font-display)',fontWeight:600,fontSize:'var(--text-2xl)',lineHeight:'var(--leading-snug)',letterSpacing:'var(--tracking-tight)',color:'var(--fg-1)'};
  const p={margin:'20px 0 0',fontFamily:'var(--font-body)',fontSize:'var(--text-base)',lineHeight:'var(--leading-body)',color:'var(--fg-1)'};
  return <ParallaxBackdrop image="../../assets/backgrounds/jwst-nebula.png" dim={0.35}>
    <div style={{maxWidth:'var(--content-max)',margin:'0 auto',padding:'72px 24px 96px'}}>
      <article style={{...scrim,padding:'56px 56px 64px'}}>
        <a href="#" onClick={e=>{e.preventDefault();onHome();}} style={{fontFamily:'var(--font-mono)',fontSize:'var(--text-sm)',color:'var(--fg-3)',textDecoration:'none'}}>← all posts</a>
        <div style={{marginTop:32,fontFamily:'var(--font-mono)',fontWeight:500,fontSize:'var(--text-xs)',letterSpacing:'var(--tracking-wide)',textTransform:'uppercase',color:'var(--amber)'}}>25 Feb 2024 · 12 min read</div>
        <h1 style={{margin:'14px 0 0',fontFamily:'var(--font-display)',fontWeight:700,fontSize:'var(--text-3xl)',lineHeight:'var(--leading-tight)',letterSpacing:'var(--tracking-tight)',color:'var(--fg-1)'}}>Running Arch Linux inside QEMU</h1>
        <div style={{display:'flex',gap:8,marginTop:20}}><Tag color="amber">virtualisation</Tag><Tag color="amber">linux</Tag></div>
        <p style={p}>I've been meaning to try Arch Linux. I wanted to install it inside a VM first, capture notes on the installation process, then if all goes well replace it as my host OS.</p>
        <h2 style={h2}>Create a virtual disk</h2>
        <p style={p}>Before we start, we need a "hard disk" that Arch will see as an available disk to install on. <code>-f raw</code> is the file format — I found <code>raw</code> the most reliable.</p>
        <CodeBlock style={{marginTop:24}} lang="bash" code={`qemu-img create -f raw arch.cow 8G`} />
        <Callout style={{marginTop:24}} kind="tip" title="Adding disk space">Stop QEMU and add space to the virtual disk: <code>qemu-img resize -f raw arch.cow +4G</code>, then resize the partition with <code>resize2fs /dev/sda3</code>.</Callout>
        <h2 style={h2}>Install Arch</h2>
        <p style={p}>Run the installer with KVM acceleration — I found <code>-accel kvm</code> a real performance improvement:</p>
        <CodeBlock style={{marginTop:24}} lang="bash" highlightLines={[2]} code={`qemu-system-x86_64 -boot menu=on -cdrom archlinux-2024.04.01-x86_64.iso \\
  -drive file=arch.cow,format=raw -m 4G -accel kvm -cpu host`} />
        <Callout style={{marginTop:24}} kind="danger" title="Pacman errors">Sometimes a dependency (llvm-libs) 404s. Run <code>pacman -Syyu</code> to sync the package database, then retry.</Callout>
        <p style={p}>That's it, you're using Arch. Happy hacking.</p>
        <div style={{display:'flex',gap:12,marginTop:48,paddingTop:32,borderTop:'1px solid var(--line-1)'}}>
          <Button variant="primary" onClick={onHome}>← Back to posts</Button>
          <Button variant="secondary" href="https://github.com/DylanMunyard/dylan-blog">View source ↗</Button>
        </div>
      </article>
    </div>
  </ParallaxBackdrop>;
}
window.Post=Post;
