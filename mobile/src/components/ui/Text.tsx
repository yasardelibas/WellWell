import { Text as RNText, type TextProps } from 'react-native';

type Variant = 'display' | 'title' | 'heading' | 'body' | 'label' | 'caption';

const variants: Record<Variant, string> = {
  display: 'text-3xl font-bold text-ink',
  title: 'text-2xl font-bold text-ink',
  heading: 'text-lg font-semibold text-ink',
  body: 'text-base text-ink',
  label: 'text-sm font-semibold text-ink-muted',
  caption: 'text-xs text-ink-subtle',
};

export interface AppTextProps extends TextProps {
  variant?: Variant;
  className?: string;
}

/**
 * Wraps Text so every screen inherits readable defaults. `allowFontScaling` stays on and
 * line counts are never capped, so medication names survive large system font sizes.
 */
export function Text({ variant = 'body', className, ...props }: AppTextProps) {
  return <RNText {...props} className={`${variants[variant]} ${className ?? ''}`} />;
}
