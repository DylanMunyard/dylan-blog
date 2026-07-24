# munyard.dev Design System

Design system for **Dylan Munyard's personal blog** — a technical coding blog at [munyard.dev](https://munyard.dev) (currently `dylan.munyard.dev`). Posts are long-form, hands-on walkthroughs of infrastructure and developer-tooling topics: installing Arch Linux in QEMU, web servers, Kubernetes/Jenkins deployment, terminal setups.

## Sources
- GitHub: [DylanMunyard/dylan-blog](https://github.com/DylanMunyard/dylan-blog) — the current blog, a stock **mkdocs-material** site (no custom theme CSS, no logo). It supplied content, tone, and structural conventions (admonitions, code-heavy posts, tables); explore it for real post copy and structure when designing.

The visual system here is a **new design** (the redesign brief), not a recreation of mkdocs-material. Brief from Dylan: dark theme; super clean typography with large type for legibility; bespoke per-post background art (generated externally per post theme) that stays **static while content scrolls**, drifting subtly with mouse movement (parallax). Palette: azure lead + ember-orange contrast on navy-black (chosen from the `guidelines/blue-exploration.html` studies — direction "2a · Azure + Ember").

## No logo
The sources contain no logo or brand mark. Wherever a mark would go, render `munyard.dev` (or `dylan@munyard.dev:~$`-style prompt text) in plain type — do not invent a logo.

## CONTENT FUNDAMENTALS
Derived from the real posts in dylan-blog:
- **First person, conversational-practical.** "I've been meaning to try Arch Linux. I wanted to install it inside a VM first…" — personal motivation up front, then hands-on steps.
- **Direct address for instructions.** "You want the ISO, not a VM image." Imperative steps: "Run `fdisk -l`", "Then reboot back into Arch."
- **Command-led writing.** Sentences frequently open with the literal command in inline code, followed by what it does: "`passwd` sets the root password".
- **Playful, self-aware titles.** File slug "what-have-they-done-to-my-little-archi-boi" vs. rendered title "Running Arch Linux inside QEMU". Hostnames like `archiboi`, users named `archie`. Sign-offs like "Happy hacking".
- **Occasional leetspeak/dev-humor**: "It makes you look like a h4ck3r".
- **Structure**: H2 sections per phase (Set up → Install → Troubleshooting → Next steps), numbered setup steps, option-reference tables, admonition callouts (`tip`, `danger`) for asides and gotchas, links to primary docs (Arch Wiki) everywhere.
- **Sentence case** headings ("Partition the disks", "Reboot into Arch"). No emoji in prose (mkdocs supported it; posts barely use it — treat emoji as off-brand).
- **Honest/unfinished is fine**: a public "Next blog posts (TODO!)" list. The blog is a lab notebook, not marketing.

## VISUAL FOUNDATIONS
- **Color**: deep navy-black surfaces (`--bg-0…3`, #070a12 → #182034), high-contrast off-white text (#eaf1fb). One hero accent: **azure** `--accent #60a5fa` (links, actions, focus, the terminal prompt mark). **Ember orange** `--amber #fb923c` for inline code, post metadata, and category tags — the complementary warm contrast to the cool base (echoes the cool-nebula / warm-star background art). Semantic info/warn/danger/success as dim-washed tints (`*-dim` at ~12-16% alpha) — color fills are rare; tinted washes + colored text are the norm. Max two accent hues visible per view.
- **Type**: `Space Grotesk` (display — titles, headings, nav), `IBM Plex Sans` (body at a big 19px/1.7), `JetBrains Mono` (code, metadata, dates, tags). Body measure ≤ 68ch. Post titles 48px, home hero up to 68px, tight tracking (-0.02em) on display sizes. Uppercase mono micro-labels with 0.08em tracking for metadata (dates, categories).
- **Backgrounds**: the signature motif. Each post gets bespoke background art (externally generated to match the post's theme) rendered as a **fixed, full-viewport layer** behind the content. Content scrolls over it; the art itself doesn't scroll but **drifts up to `--parallax-shift` (16px) following the cursor**, eased with `--ease-out`. Content sits on a scrim: `--scrim-content` (82% bg) + `backdrop-filter: blur(var(--scrim-blur))`. Never place text directly on raw art. Where no art exists, plain `--bg-1`.
- **Cards**: `--surface-card` fill, 1px `--border-default`, `--radius-lg` (14px), `--shadow-card`. Hover: border brightens to `--border-strong`, translateY(-2px), 200ms `--ease-out`. No colored left-border cards.
- **Borders & radii**: hairlines everywhere (#232936); radii 6/10/14px, pills for tags.
- **Shadows/glow**: soft deep shadows (`--shadow-card/raised`); `--glow-accent` reserved for the single primary action or active state. Focus = `--ring-focus` double ring.
- **Motion**: restrained. Fades and small translates only, 120–400ms, `--ease-out`. No bounces. Parallax drift is the one continuous motion.
- **Hover states**: text links brighten to `--accent-strong` + underline (3px offset); surfaces lighten one step (bg-2→bg-3); buttons brighten, press scales to 0.98.
- **Transparency & blur**: only in the content scrim over background art and sticky headers. Not decorative.
- **Imagery**: terminal screenshots framed in a card (radius-lg, hairline border) — never bare. Background art should read as atmospheric/dim (dark, cool, low-contrast) so mint/amber pop.
- **Layout**: single centered prose column (720px) for posts; 1120px grid for the index. Header is sticky, blurred, hairline-bottomed.

## ICONOGRAPHY
- The source repo has **no icon set** (mkdocs-material's Material icons are theme-internal; none referenced in content except one `:material-close-network-outline:` shortcode). No icon font is part of this brand.
- Approach: **text-first**. Unicode/ASCII glyphs in mono do most icon work: `$` prompt, `→` links/next, `↳` nested steps, `#` headings/anchors, `▲▼` sort, `●` status. This matches the terminal aesthetic.
- Where real icons are unavoidable (UI chrome), use **Lucide** from CDN at 1.5px stroke — a substitution, flagged: no icon system existed in the sources. Document any icon you add.
- Emoji: not used.
- Assets copied: `assets/backgrounds/arch-qemu-header.jpg` (the one piece of bespoke-style imagery in the repo — an example of per-post background art direction). Author avatar lives at GitHub: `https://avatars.githubusercontent.com/u/4288180?s=400`.

## Intentional additions
No component library existed in the sources (stock mkdocs-material), so a standard set sized to a blog was authored: Button, Tag, Callout, CodeBlock, PostCard, ParallaxBackdrop. ParallaxBackdrop exists because the static-background-with-mouse-drift behavior is the brief's core motif.

## Index
- `styles.css` — global entry; imports everything in `tokens/`.
- `tokens/` — `colors.css`, `typography.css`, `spacing.css`, `effects.css`, `code.css` (syntax palette).
- `components/core/` — Button, Tag, Callout, CodeBlock, PostCard, ParallaxBackdrop (+ `.d.ts`, `.prompt.md`, specimen cards).
- `ui_kits/blog/` — Home index + post page recreations of the new design.
- `guidelines/` — foundation specimen cards.
- `assets/backgrounds/` — sample background art.
- `SKILL.md` — agent skill entry point.
