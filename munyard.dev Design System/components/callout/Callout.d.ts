/**
 * Admonition block for asides and gotchas — the design's version of mkdocs `!!! tip` / `!!! danger`.
 */
export interface CalloutProps {
  kind?: 'tip' | 'info' | 'warning' | 'danger';
  title?: string;
  children: React.ReactNode;
  style?: React.CSSProperties;
}
