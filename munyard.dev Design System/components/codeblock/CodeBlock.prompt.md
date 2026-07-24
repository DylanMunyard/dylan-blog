Fenced code block — line numbers, filename/lang chip, copy button (mkdocs `content.code.copy` equivalent), optional highlighted lines.

```jsx
<CodeBlock lang="bash" highlightLines={[2]} code={`qemu-img create -f raw arch.cow 8G\npacman -S base-devel git`} />
```

Plain-text rendering; wrap tokens manually with syntax vars (`--code-keyword` etc.) only in bespoke specimens.
