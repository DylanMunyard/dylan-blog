/**
 * Fenced code block with filename/lang chip, line numbers, copy button, and optional line highlights.
 */
export interface CodeBlockProps {
  code: string;
  lang?: string;
  filename?: string;
  /** 1-based line numbers to wash with --code-line-hl */
  highlightLines?: number[];
  style?: React.CSSProperties;
}
