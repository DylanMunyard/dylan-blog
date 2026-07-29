/* @ds-bundle: {"format":4,"namespace":"MunyardDevDesignSystem_0136e3","components":[{"name":"ParallaxBackdrop","sourcePath":"components/backdrop/ParallaxBackdrop.jsx"},{"name":"Button","sourcePath":"components/button/Button.jsx"},{"name":"Callout","sourcePath":"components/callout/Callout.jsx"},{"name":"CodeBlock","sourcePath":"components/codeblock/CodeBlock.jsx"},{"name":"PostCard","sourcePath":"components/postcard/PostCard.jsx"},{"name":"Tag","sourcePath":"components/tag/Tag.jsx"}],"sourceHashes":{"components/backdrop/ParallaxBackdrop.jsx":"fbb3eab43d04","components/button/Button.jsx":"fe9b78b2639b","components/callout/Callout.jsx":"4d88fc789952","components/codeblock/CodeBlock.jsx":"6037f78767c4","components/postcard/PostCard.jsx":"1fb84fba6a4c","components/tag/Tag.jsx":"2ef844812be5","ui_kits/blog/Chrome.jsx":"c85c74c69573","ui_kits/blog/Home.jsx":"750e2218e3a1","ui_kits/blog/Post.jsx":"029ab86c9601"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.MunyardDevDesignSystem_0136e3 = window.MunyardDevDesignSystem_0136e3 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/backdrop/ParallaxBackdrop.jsx
try { (() => {
function ParallaxBackdrop({
  image,
  dim = 0.55,
  shift = 16,
  children,
  style
}) {
  const ref = React.useRef(null);
  const [pos, setPos] = React.useState({
    x: 0,
    y: 0
  });
  React.useEffect(() => {
    const onMove = e => {
      const w = window.innerWidth,
        h = window.innerHeight;
      setPos({
        x: (e.clientX / w - 0.5) * 2,
        y: (e.clientY / h - 0.5) * 2
      });
    };
    window.addEventListener('mousemove', onMove);
    return () => window.removeEventListener('mousemove', onMove);
  }, []);
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    ref: ref,
    "aria-hidden": "true",
    style: {
      position: 'fixed',
      inset: -shift * 2,
      zIndex: 0,
      background: `url(${image}) center/cover no-repeat var(--bg-0)`,
      transform: `translate(${-pos.x * shift}px,${-pos.y * shift}px)`,
      transition: 'transform 400ms var(--ease-out)',
      willChange: 'transform',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: `rgba(7,9,14,${dim})`
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'linear-gradient(180deg,rgba(11,14,20,0.2) 0%,rgba(11,14,20,0.65) 100%)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 1
    }
  }, children));
}
Object.assign(__ds_scope, { ParallaxBackdrop });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/backdrop/ParallaxBackdrop.jsx", error: String((e && e.message) || e) }); }

// components/button/Button.jsx
try { (() => {
function Button({
  variant = 'primary',
  size = 'md',
  children,
  href,
  disabled,
  onClick,
  style
}) {
  const pad = size === 'sm' ? '8px 14px' : size === 'lg' ? '14px 24px' : '11px 18px';
  const fs = size === 'sm' ? '0.875rem' : size === 'lg' ? '1.0625rem' : '0.9375rem';
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 8,
    fontFamily: 'var(--font-display)',
    fontWeight: 600,
    fontSize: fs,
    lineHeight: 1,
    padding: pad,
    borderRadius: 'var(--radius-md)',
    border: '1px solid transparent',
    cursor: disabled ? 'not-allowed' : 'pointer',
    opacity: disabled ? 0.45 : 1,
    textDecoration: 'none',
    transition: 'all var(--dur-fast) var(--ease-out)',
    userSelect: 'none'
  };
  const variants = {
    primary: {
      background: 'var(--accent)',
      color: 'var(--accent-ink)'
    },
    secondary: {
      background: 'var(--bg-3)',
      color: 'var(--fg-1)',
      borderColor: 'var(--line-2)'
    },
    ghost: {
      background: 'transparent',
      color: 'var(--fg-2)'
    },
    danger: {
      background: 'var(--danger-dim)',
      color: 'var(--danger)',
      borderColor: 'transparent'
    }
  };
  const [hover, setHover] = React.useState(false);
  const [press, setPress] = React.useState(false);
  const hoverStyles = {
    primary: {
      background: 'var(--accent-strong)'
    },
    secondary: {
      background: 'var(--bg-3)',
      borderColor: 'var(--line-2)',
      color: 'var(--accent)'
    },
    ghost: {
      color: 'var(--fg-1)',
      background: 'var(--bg-2)'
    },
    danger: {
      background: 'rgba(253,164,175,0.2)'
    }
  };
  const s = {
    ...base,
    ...variants[variant],
    ...(hover && !disabled ? hoverStyles[variant] : {}),
    transform: press && !disabled ? 'scale(0.98)' : 'none',
    ...style
  };
  const Tag = href ? 'a' : 'button';
  return /*#__PURE__*/React.createElement(Tag, {
    href: href,
    disabled: disabled,
    onClick: disabled ? undefined : onClick,
    style: s,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => {
      setHover(false);
      setPress(false);
    },
    onMouseDown: () => setPress(true),
    onMouseUp: () => setPress(false)
  }, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/button/Button.jsx", error: String((e && e.message) || e) }); }

// components/callout/Callout.jsx
try { (() => {
function Callout({
  kind = 'tip',
  title,
  children,
  style
}) {
  const map = {
    tip: ['var(--accent)', 'var(--accent-dim)', 'TIP'],
    info: ['var(--info)', 'var(--info-dim)', 'NOTE'],
    warning: ['var(--warn)', 'var(--warn-dim)', 'WARNING'],
    danger: ['var(--danger)', 'var(--danger-dim)', 'DANGER']
  };
  const [fg, bg, label] = map[kind] || map.tip;
  return /*#__PURE__*/React.createElement("aside", {
    style: {
      background: 'var(--bg-2)',
      border: '1px solid var(--line-1)',
      borderRadius: 'var(--radius-lg)',
      overflow: 'hidden',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '10px 18px',
      background: bg
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontWeight: 600,
      fontSize: 'var(--text-xs)',
      letterSpacing: 'var(--tracking-wide)',
      color: fg
    }
  }, title ? `${label} — ${title}` : label)), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '14px 18px',
      fontFamily: 'var(--font-body)',
      fontSize: '1.0625rem',
      lineHeight: 1.65,
      color: 'var(--fg-2)'
    }
  }, children));
}
Object.assign(__ds_scope, { Callout });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/callout/Callout.jsx", error: String((e && e.message) || e) }); }

// components/codeblock/CodeBlock.jsx
try { (() => {
function CodeBlock({
  code,
  lang,
  filename,
  highlightLines = [],
  style
}) {
  const [copied, setCopied] = React.useState(false);
  const lines = (code || '').replace(/\n$/, '').split('\n');
  const copy = () => {
    try {
      navigator.clipboard.writeText(code);
    } catch (e) {}
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };
  return /*#__PURE__*/React.createElement("figure", {
    style: {
      margin: 0,
      background: 'var(--code-bg)',
      border: '1px solid var(--line-1)',
      borderRadius: 'var(--radius-lg)',
      overflow: 'hidden',
      boxShadow: 'var(--shadow-card)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '8px 16px',
      borderBottom: '1px solid var(--line-1)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-xs)',
      fontWeight: 500,
      color: 'var(--fg-3)'
    }
  }, filename || lang || 'shell'), /*#__PURE__*/React.createElement("button", {
    onClick: copy,
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-xs)',
      fontWeight: 500,
      color: copied ? 'var(--accent)' : 'var(--fg-3)',
      background: 'none',
      border: 'none',
      cursor: 'pointer',
      padding: '2px 4px'
    }
  }, copied ? 'copied' : 'copy')), /*#__PURE__*/React.createElement("pre", {
    style: {
      margin: 0,
      padding: '14px 0',
      overflowX: 'auto'
    }
  }, lines.map((l, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: 'flex',
      background: highlightLines.includes(i + 1) ? 'var(--code-line-hl)' : 'transparent'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 'none',
      width: 44,
      textAlign: 'right',
      paddingRight: 16,
      fontFamily: 'var(--font-mono)',
      fontSize: '0.9375rem',
      lineHeight: 1.7,
      color: 'var(--code-gutter)',
      userSelect: 'none'
    }
  }, i + 1), /*#__PURE__*/React.createElement("code", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: '0.9375rem',
      lineHeight: 1.7,
      color: 'var(--code-fg)',
      whiteSpace: 'pre',
      paddingRight: 20,
      background: 'none'
    }
  }, l || ' ')))));
}
Object.assign(__ds_scope, { CodeBlock });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/codeblock/CodeBlock.jsx", error: String((e && e.message) || e) }); }

// components/tag/Tag.jsx
try { (() => {
function Tag({
  children,
  color = 'neutral',
  active,
  onClick,
  style
}) {
  const map = {
    neutral: ['var(--fg-2)', 'transparent', 'var(--line-2)'],
    mint: ['var(--accent)', 'var(--accent-dim)', 'transparent'],
    amber: ['var(--amber)', 'var(--amber-dim)', 'transparent'],
    info: ['var(--info)', 'var(--info-dim)', 'transparent']
  };
  const [fg, bg, bd] = map[color] || map.neutral;
  const [hover, setHover] = React.useState(false);
  return /*#__PURE__*/React.createElement("span", {
    onClick: onClick,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      fontFamily: 'var(--font-mono)',
      fontWeight: 500,
      fontSize: 'var(--text-xs)',
      letterSpacing: '0.03em',
      padding: '4px 12px',
      borderRadius: 'var(--radius-full)',
      color: active ? 'var(--accent-ink)' : fg,
      background: active ? 'var(--accent)' : bg,
      border: `1px solid ${active ? 'transparent' : bd}`,
      cursor: onClick ? 'pointer' : 'default',
      opacity: hover && onClick ? 0.85 : 1,
      transition: 'opacity var(--dur-fast) var(--ease-out)',
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { Tag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/tag/Tag.jsx", error: String((e && e.message) || e) }); }

// components/postcard/PostCard.jsx
try { (() => {
function PostCard({
  title,
  date,
  readTime,
  excerpt,
  categories = [],
  image,
  href = '#',
  style
}) {
  const [hover, setHover] = React.useState(false);
  return /*#__PURE__*/React.createElement("a", {
    href: href,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      display: 'block',
      textDecoration: 'none',
      background: 'var(--bg-2)',
      border: `1px solid ${hover ? 'var(--line-2)' : 'var(--line-1)'}`,
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      overflow: 'hidden',
      transform: hover ? 'translateY(-2px)' : 'none',
      transition: 'all var(--dur-base) var(--ease-out)',
      ...style
    }
  }, image && /*#__PURE__*/React.createElement("div", {
    style: {
      height: 160,
      background: `url(${image}) center/cover`,
      borderBottom: '1px solid var(--line-1)',
      filter: hover ? 'none' : 'saturate(0.85)',
      transition: 'filter var(--dur-base) var(--ease-out)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '20px 24px 22px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontWeight: 500,
      fontSize: 'var(--text-xs)',
      letterSpacing: 'var(--tracking-wide)',
      textTransform: 'uppercase',
      color: 'var(--fg-3)'
    }
  }, date, readTime ? ` · ${readTime}` : ''), /*#__PURE__*/React.createElement("h3", {
    style: {
      margin: '10px 0 0',
      fontFamily: 'var(--font-display)',
      fontWeight: 600,
      fontSize: '1.5rem',
      lineHeight: 1.25,
      letterSpacing: 'var(--tracking-tight)',
      color: hover ? 'var(--accent)' : 'var(--fg-1)',
      transition: 'color var(--dur-fast) var(--ease-out)'
    }
  }, title), excerpt && /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '10px 0 0',
      fontFamily: 'var(--font-body)',
      fontSize: '1rem',
      lineHeight: 1.6,
      color: 'var(--fg-2)'
    }
  }, excerpt), categories.length > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 16
    }
  }, categories.map(c => /*#__PURE__*/React.createElement(__ds_scope.Tag, {
    key: c,
    color: "amber"
  }, c)))));
}
Object.assign(__ds_scope, { PostCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/postcard/PostCard.jsx", error: String((e && e.message) || e) }); }

// ui_kits/blog/Chrome.jsx
try { (() => {
function Header({
  onHome
}) {
  return /*#__PURE__*/React.createElement("header", {
    style: {
      position: 'sticky',
      top: 0,
      zIndex: 5,
      background: 'rgba(11,14,20,0.7)',
      backdropFilter: 'blur(14px)',
      WebkitBackdropFilter: 'blur(14px)',
      borderBottom: '1px solid var(--line-1)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: 'var(--page-max)',
      margin: '0 auto',
      padding: '0 32px',
      height: 64,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: "#",
    onClick: e => {
      e.preventDefault();
      onHome();
    },
    style: {
      fontFamily: 'var(--font-mono)',
      fontWeight: 600,
      fontSize: '1.0625rem',
      color: 'var(--fg-1)',
      textDecoration: 'none'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--accent)'
    }
  }, "dylan@munyard.dev"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--fg-3)'
    }
  }, ":~$"), /*#__PURE__*/React.createElement("span", {
    className: "blink",
    style: {
      color: 'var(--fg-2)'
    }
  }, "\u258A")), /*#__PURE__*/React.createElement("nav", {
    style: {
      display: 'flex',
      gap: 28,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: "#",
    onClick: e => {
      e.preventDefault();
      onHome();
    },
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 500,
      fontSize: '0.9375rem',
      color: 'var(--fg-2)',
      textDecoration: 'none'
    }
  }, "Posts"), /*#__PURE__*/React.createElement("a", {
    href: "#",
    onClick: e => e.preventDefault(),
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 500,
      fontSize: '0.9375rem',
      color: 'var(--fg-2)',
      textDecoration: 'none'
    }
  }, "About"), /*#__PURE__*/React.createElement("a", {
    href: "https://github.com/DylanMunyard",
    style: {
      fontFamily: 'var(--font-mono)',
      fontWeight: 500,
      fontSize: '0.875rem',
      color: 'var(--fg-3)',
      textDecoration: 'none'
    }
  }, "github \u2197"))));
}
function Footer() {
  return /*#__PURE__*/React.createElement("footer", {
    style: {
      borderTop: '1px solid var(--line-1)',
      marginTop: 96
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: 'var(--page-max)',
      margin: '0 auto',
      padding: '32px',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'baseline'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-xs)',
      color: 'var(--fg-3)'
    }
  }, "\xA9 2026 Dylan Munyard \xB7 munyard.dev"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-xs)',
      color: 'var(--fg-3)'
    }
  }, "Happy hacking")));
}
Object.assign(window, {
  Header,
  Footer
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/blog/Chrome.jsx", error: String((e && e.message) || e) }); }

// ui_kits/blog/Home.jsx
try { (() => {
function Home({
  onOpenPost
}) {
  const {
    PostCard,
    Tag
  } = window.MunyardDevDesignSystem_0136e3;
  const [filter, setFilter] = React.useState('all');
  const posts = [{
    id: 'arch',
    title: 'Running Arch Linux inside QEMU',
    date: '25 Feb 2024',
    readTime: '12 min read',
    cats: ['virtualisation', 'linux'],
    excerpt: 'Install Arch in a VM first, capture notes on the process, then if all goes well replace it as my host OS.',
    image: '../../assets/backgrounds/arch-qemu-header.jpg'
  }, {
    id: 'jenkins',
    title: 'Deploying this blog with Jenkins on Kubernetes',
    date: '14 Mar 2024',
    readTime: '8 min read',
    cats: ['kubernetes', 'ci'],
    excerpt: 'Build agents as pods, a role binding for the blog namespace, and one kubectl apply.'
  }, {
    id: 'zsh',
    title: 'Pimp your terminal: zsh, Oh My Posh and Nerd Fonts',
    date: '02 Apr 2024',
    readTime: '6 min read',
    cats: ['terminal'],
    excerpt: 'Look like a h4ck3r while getting genuinely useful git context in your prompt.'
  }];
  const cats = ['all', 'virtualisation', 'linux', 'kubernetes', 'ci', 'terminal'];
  const shown = posts.filter(p => filter === 'all' || p.cats.includes(filter));
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("section", {
    style: {
      maxWidth: 'var(--page-max)',
      margin: '0 auto',
      padding: '96px 32px 64px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontWeight: 500,
      fontSize: 'var(--text-xs)',
      letterSpacing: 'var(--tracking-wide)',
      textTransform: 'uppercase',
      color: 'var(--amber)'
    }
  }, "~ a lab notebook"), /*#__PURE__*/React.createElement("h1", {
    style: {
      margin: '16px 0 0',
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 'var(--text-4xl)',
      lineHeight: 'var(--leading-tight)',
      letterSpacing: 'var(--tracking-tight)',
      color: 'var(--fg-1)',
      maxWidth: 800
    }
  }, "Dylan's blog"), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '20px 0 0',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--text-lg)',
      lineHeight: 1.6,
      color: 'var(--fg-2)',
      maxWidth: '56ch'
    }
  }, "I'm Dylan. I write down what I break and how I fix it \u2014 Arch installs, Kubernetes deploys, web servers, shells."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10,
      flexWrap: 'wrap',
      marginTop: 36
    }
  }, cats.map(c => /*#__PURE__*/React.createElement(Tag, {
    key: c,
    active: filter === c,
    onClick: () => setFilter(c),
    color: filter === c ? undefined : 'neutral'
  }, c)))), /*#__PURE__*/React.createElement("section", {
    style: {
      maxWidth: 'var(--page-max)',
      margin: '0 auto',
      padding: '0 32px',
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fill,minmax(320px,1fr))',
      gap: 24
    }
  }, shown.map(p => /*#__PURE__*/React.createElement("div", {
    key: p.id,
    onClick: e => {
      e.preventDefault();
      onOpenPost(p.id);
    }
  }, /*#__PURE__*/React.createElement(PostCard, {
    title: p.title,
    date: p.date,
    readTime: p.readTime,
    excerpt: p.excerpt,
    categories: p.cats,
    image: p.image,
    href: "#"
  })))));
}
window.Home = Home;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/blog/Home.jsx", error: String((e && e.message) || e) }); }

// ui_kits/blog/Post.jsx
try { (() => {
function Post({
  onHome
}) {
  const {
    ParallaxBackdrop,
    Callout,
    CodeBlock,
    Tag,
    Button
  } = window.MunyardDevDesignSystem_0136e3;
  const scrim = {
    background: 'var(--scrim-content)',
    backdropFilter: 'blur(var(--scrim-blur))',
    WebkitBackdropFilter: 'blur(var(--scrim-blur))',
    border: '1px solid var(--line-1)',
    borderRadius: 'var(--radius-lg)'
  };
  const h2 = {
    margin: '56px 0 0',
    fontFamily: 'var(--font-display)',
    fontWeight: 600,
    fontSize: 'var(--text-2xl)',
    lineHeight: 'var(--leading-snug)',
    letterSpacing: 'var(--tracking-tight)',
    color: 'var(--fg-1)'
  };
  const p = {
    margin: '20px 0 0',
    fontFamily: 'var(--font-body)',
    fontSize: 'var(--text-base)',
    lineHeight: 'var(--leading-body)',
    color: 'var(--fg-1)'
  };
  return /*#__PURE__*/React.createElement(ParallaxBackdrop, {
    image: "../../assets/backgrounds/jwst-nebula.png",
    dim: 0.35
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: 'var(--content-max)',
      margin: '0 auto',
      padding: '72px 24px 96px'
    }
  }, /*#__PURE__*/React.createElement("article", {
    style: {
      ...scrim,
      padding: '56px 56px 64px'
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: "#",
    onClick: e => {
      e.preventDefault();
      onHome();
    },
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-sm)',
      color: 'var(--fg-3)',
      textDecoration: 'none'
    }
  }, "\u2190 all posts"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 32,
      fontFamily: 'var(--font-mono)',
      fontWeight: 500,
      fontSize: 'var(--text-xs)',
      letterSpacing: 'var(--tracking-wide)',
      textTransform: 'uppercase',
      color: 'var(--amber)'
    }
  }, "25 Feb 2024 \xB7 12 min read"), /*#__PURE__*/React.createElement("h1", {
    style: {
      margin: '14px 0 0',
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 'var(--text-3xl)',
      lineHeight: 'var(--leading-tight)',
      letterSpacing: 'var(--tracking-tight)',
      color: 'var(--fg-1)'
    }
  }, "Running Arch Linux inside QEMU"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 20
    }
  }, /*#__PURE__*/React.createElement(Tag, {
    color: "amber"
  }, "virtualisation"), /*#__PURE__*/React.createElement(Tag, {
    color: "amber"
  }, "linux")), /*#__PURE__*/React.createElement("p", {
    style: p
  }, "I've been meaning to try Arch Linux. I wanted to install it inside a VM first, capture notes on the installation process, then if all goes well replace it as my host OS."), /*#__PURE__*/React.createElement("h2", {
    style: h2
  }, "Create a virtual disk"), /*#__PURE__*/React.createElement("p", {
    style: p
  }, "Before we start, we need a \"hard disk\" that Arch will see as an available disk to install on. ", /*#__PURE__*/React.createElement("code", null, "-f raw"), " is the file format \u2014 I found ", /*#__PURE__*/React.createElement("code", null, "raw"), " the most reliable."), /*#__PURE__*/React.createElement(CodeBlock, {
    style: {
      marginTop: 24
    },
    lang: "bash",
    code: `qemu-img create -f raw arch.cow 8G`
  }), /*#__PURE__*/React.createElement(Callout, {
    style: {
      marginTop: 24
    },
    kind: "tip",
    title: "Adding disk space"
  }, "Stop QEMU and add space to the virtual disk: ", /*#__PURE__*/React.createElement("code", null, "qemu-img resize -f raw arch.cow +4G"), ", then resize the partition with ", /*#__PURE__*/React.createElement("code", null, "resize2fs /dev/sda3"), "."), /*#__PURE__*/React.createElement("h2", {
    style: h2
  }, "Install Arch"), /*#__PURE__*/React.createElement("p", {
    style: p
  }, "Run the installer with KVM acceleration \u2014 I found ", /*#__PURE__*/React.createElement("code", null, "-accel kvm"), " a real performance improvement:"), /*#__PURE__*/React.createElement(CodeBlock, {
    style: {
      marginTop: 24
    },
    lang: "bash",
    highlightLines: [2],
    code: `qemu-system-x86_64 -boot menu=on -cdrom archlinux-2024.04.01-x86_64.iso \\
  -drive file=arch.cow,format=raw -m 4G -accel kvm -cpu host`
  }), /*#__PURE__*/React.createElement(Callout, {
    style: {
      marginTop: 24
    },
    kind: "danger",
    title: "Pacman errors"
  }, "Sometimes a dependency (llvm-libs) 404s. Run ", /*#__PURE__*/React.createElement("code", null, "pacman -Syyu"), " to sync the package database, then retry."), /*#__PURE__*/React.createElement("p", {
    style: p
  }, "That's it, you're using Arch. Happy hacking."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 12,
      marginTop: 48,
      paddingTop: 32,
      borderTop: '1px solid var(--line-1)'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    onClick: onHome
  }, "\u2190 Back to posts"), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    href: "https://github.com/DylanMunyard/dylan-blog"
  }, "View source \u2197")))));
}
window.Post = Post;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/blog/Post.jsx", error: String((e && e.message) || e) }); }

__ds_ns.ParallaxBackdrop = __ds_scope.ParallaxBackdrop;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Callout = __ds_scope.Callout;

__ds_ns.CodeBlock = __ds_scope.CodeBlock;

__ds_ns.PostCard = __ds_scope.PostCard;

__ds_ns.Tag = __ds_scope.Tag;

})();
