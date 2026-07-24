/**
 * The signature background layer: fixed full-viewport bespoke art that stays static while content scrolls, drifting subtly with the cursor. Content renders as children above it.
 */
export interface ParallaxBackdropProps {
  /** URL of the post's bespoke background art */
  image: string;
  /** 0–1 darkening overlay strength. Default 0.55 */
  dim?: number;
  /** Max px drift on mouse move. Default 16 (--parallax-shift) */
  shift?: number;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
