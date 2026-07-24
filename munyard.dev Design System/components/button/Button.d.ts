/**
 * Action button. Primary = the one mint action per view; secondary for neutral actions; ghost for tertiary; danger rare.
 * @startingPoint section="Components" subtitle="Primary, secondary, ghost, danger" viewport="700x180"
 */
export interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  href?: string;
  disabled?: boolean;
  onClick?: () => void;
  children: React.ReactNode;
  style?: React.CSSProperties;
}
