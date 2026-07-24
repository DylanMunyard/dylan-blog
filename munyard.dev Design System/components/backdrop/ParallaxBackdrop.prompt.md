The signature motif: fixed full-viewport art behind the page. Content scrolls over it; the art drifts up to `shift` px following the cursor (eased, 400ms). Wraps page content as children.

```jsx
<ParallaxBackdrop image="assets/backgrounds/arch-qemu-header.jpg" dim={0.55}>
  <main>…post content on a scrim…</main>
</ParallaxBackdrop>
```

Always put text on `--scrim-content` + blur, never on raw art. `dim` darkens the art (default 0.55); a vertical protection gradient is built in.
