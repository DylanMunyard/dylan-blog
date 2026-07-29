import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import mermaid from 'astro-mermaid';

// https://astro.build/config
export default defineConfig({
  site: 'https://dylan.munyard.dev',
  integrations: [
    mermaid({
      theme: 'dark',
      mermaidConfig: {
        flowchart: {
          nodeSpacing: 80,
          rankSpacing: 120,
          diagramPadding: 30
        }
      }
    }),
    mdx()
  ],
  markdown: {
    shikiConfig: {
      theme: 'dracula',
      wrap: true
    }
  }
});
