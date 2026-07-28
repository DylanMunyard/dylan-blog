---
name: format-blog-post
description: Formats one of Dylan's rough blog drafts in src/content/blog/*.md into publish-ready markdown for this Astro site. Use whenever Dylan asks to "format", "clean up the markdown on", "run the formatter on", or "finish" a blog post/draft — or references bracketed notes-to-self he left himself inside a draft (e.g. "[Put a picture here]", "[<check box ticked here>]", "[Summarize ... in a table]"). Also trigger if he says a post is "rough" or "just words for now" and wants it turned into something postable. Do NOT use this for writing new blog content from scratch, or for rewriting/improving prose — this skill explicitly never touches Dylan's wording.
---

# Format Blog Post

Dylan drafts posts as plain rough text, in his own words, in the order he wants them. This skill takes that draft and:
1. carries out any bracketed instructions he left himself, then removes the bracket
2. applies this repo's markdown formatting conventions
3. never, ever touches his actual words

## The golden rule

**Do not change Dylan's words.** No fixing typos, no grammar corrections, no rephrasing, no tightening sentences, no reordering paragraphs. His voice is the product — copy it through byte-for-byte. This applies to every word outside of a bracketed instruction. When in doubt about whether an edit counts as "just formatting" or "changing his words," don't make it.

The one place typos/grammar are allowed to surface at all is a **Feedback** section you print in your chat reply at the end (see step 4) — never inside the file itself.

## No emojis, ever

Dylan does not want emoji anywhere in a published post — not in headings, not in callout titles, not as bullet decoration. If you're tempted to reach for one to signal "this is a tip" or "this is a warning," use the `<Callout>` component's `kind` (color) instead — see Step 1.

## Step 1: Read the draft and this repo's style precedent

Read the target `.md` file (path given by Dylan, or the most recently modified file under `src/content/blog/` if he just points at "the draft").

Then read `src/content/blog/arch-linux-qemu.md` — it's the style precedent for this repo and is the source of truth for conventions, not this document. In particular notice:
- `##` / `###` headings for sections
- fenced ` ```bash ` blocks for commands meant to be run, single backticks for inline commands/paths/flags
- markdown tables for option/reference breakdowns
- plain `![alt](/path.png)` images (paths are root-relative because Astro serves `public/` at `/`)
- markdown links `[text](url)` rather than bare pasted URLs
- callouts use the real `<Callout kind="tip|info|warn|danger" title="...">` component from `src/components/Callout.astro` — colored background only, no emoji, no badge label (the component prints just the title, bolded and sized up)

`Callout.astro` is an Astro component, so it only renders inside `.mdx` files, not `.md`. If the draft you're formatting is `.md` and needs a callout, convert it: `git mv path/to/post.md path/to/post.mdx`, then add `import Callout from '../../components/Callout.astro';` on its own line right after the closing `---` of the frontmatter, before the first paragraph. Content collections in this repo happily mix `.md` and `.mdx` side by side, so only convert the file that actually needs a callout.

Pick `kind` by the emotional register of the note, not a flat tip-vs-warning binary:
- `tip` (green) — a clever discovery, a hack, something that worked out well
- `info` (soft blue) — a reflective aside, a mild regret, "in hindsight" energy
- `warn` (orange) — a literal caution: heat, fragility, something to watch out for
- `danger` (red) — reserved for something that can actually break or damage something if ignored

Wrap the existing sentence(s) verbatim between the opening and closing tags — same golden-rule treatment as a blockquote would get, just a different container:
```mdx
<Callout kind="warn" title="They run hot">
They run incredibly hot – I leave the side off my server and let the disk enclosure blow its fan onto it.
</Callout>
```

## Step 2: Find and fulfil every bracketed instruction

Anything Dylan wrote in `[...]` inside the draft is an instruction to *you*, not content to publish. Find each one, do what it says, and remove the bracket text — none of it should survive into the final file. Common ones:

- **`[Put a picture here ...]`** (may name a path, e.g. `public/building-a-home-server/side.webp`, or just say "here"). Confirm the referenced file actually exists (check `public/`) before inserting anything. Convert the path to root-relative the way Astro serves it: `public/foo/bar.webp` → `/foo/bar.webp`. Write a real `![alt](...)` image reference at that spot, placed appropriately relative to the surrounding paragraph. Write the alt text yourself from context — it's metadata for accessibility, not Dylan's prose, so the golden rule doesn't block you here. If a path is given but the file doesn't exist, or "here" is given with no path and it's ambiguous which asset he means, stop and ask rather than guessing.
- **`[<check box ticked here>]`** followed by label text on the same line — turn the whole line into a checked list item: `- [x] <label text, verbatim>`. Keep the label word-for-word; you're only adding the `- [x]` markdown syntax.
- **`[Summarize all of the above in a table]`** — build a markdown table condensing the section(s) above it (your own summarization, since a table is new structure, not a rewording of his sentences), insert it in place of the bracket.
- **Any other `[...]`** — read it as an instruction, do your best to fulfil its intent, and remove it. If it's genuinely unclear what's being asked, ask Dylan rather than guessing at something structural and hard to undo.

## Step 3: Apply structural formatting to the rest

Working around the instructions you just resolved, reformat the draft to match the conventions from Step 1:
- Ad-hoc headers like `-- Hardware` or `* What if...?` become proper `##`/`###` headings (pick heading level by how the draft nests them).
- Watch for a second, subtler heading style: a paragraph that opens with a short flat label + period before getting into the actual sentence — `RAM, 8G is enough...`, `Form factor. This refers to...`, `Hard drives. You can start simple...`. That label already *is* the heading Dylan wrote, just inline instead of on its own marker line. If you're breaking a section into subheadings and one of your new subsections starts this way, don't invent a separate heading title and leave the label sitting there — you'll get an awkward duplicate (heading says "RAM", next line starts "RAM, ..."), or worse, a mismatch (heading says "Storage", the label actually says "Hard drives" — now you've overridden his word with your own). Instead, lift his exact label word(s) up into the heading and delete them from the body, the same way `-- Hardware` becomes `## Hardware` with nothing left behind. Test before doing this: is it a flat, disposable label (interchangeable with a heading, no voice of its own — like "Form factor.") or a stylistic/rhetorical sentence that just happens to open the paragraph (like "RAID or not to RAID?", which plays on "to be or not to be")? Only fold the former into a heading; the latter is Dylan's voice and stays in the body exactly as written, even if you also give that paragraph its own heading.
- Commands, file paths, flags, and config values referenced inline get backticks; multi-line or standalone commands get fenced ` ```bash ` blocks.
- Bare pasted URLs become `[sensible link text](url)`.
- Loose bullet-like lines become real markdown list syntax.
- Asides that read like a tip/warning/gotcha become a `<Callout>` per Step 1 — this doesn't require touching the wording itself, you're wrapping the existing sentence(s), not editing them.

If something is genuinely ambiguous — is this line a heading or just an emphatic sentence? — leave it as plain prose rather than guessing and imposing structure that wasn't there.

## Step 4: Edit the file, then report Feedback separately

Write the formatted result back to the file in place.

Then, in your chat reply (never in the file), add a section like:

```
## Feedback
- <line/location>: <the typo or grammar issue you noticed>
```

This is informational only — list what you noticed, don't fix it. Dylan will explicitly ask if he wants a rewrite. If you noticed nothing worth flagging, say so briefly rather than omitting the section.
