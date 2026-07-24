Admonition block — replaces mkdocs `!!! tip` / `!!! danger` asides in posts.

```jsx
<Callout kind="tip" title="Adding disk space">Stop QEMU and resize: <code>qemu-img resize -f raw arch.cow +4G</code></Callout>
```

`kind` tip|info|warning|danger sets header tint + label; optional `title` appends after the label.
