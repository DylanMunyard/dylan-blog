/**
 * Blog index card: optional art thumbnail, mono metadata, display title, excerpt, category tags.
 * @startingPoint section="Components" subtitle="Index card with art, meta, tags" viewport="420x420"
 */
export interface PostCardProps {
  title: string;
  /** e.g. "25 Feb 2024" */
  date: string;
  /** e.g. "12 min read" */
  readTime?: string;
  excerpt?: string;
  categories?: string[];
  /** URL of the post's bespoke background art */
  image?: string;
  href?: string;
  style?: React.CSSProperties;
}
