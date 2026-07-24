/**
 * Category/topic pill in mono type. Used for post categories and filters.
 */
export interface TagProps {
  color?: 'neutral' | 'mint' | 'amber' | 'info';
  active?: boolean;
  onClick?: () => void;
  children: React.ReactNode;
  style?: React.CSSProperties;
}
