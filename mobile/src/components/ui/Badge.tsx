import { View } from 'react-native';

import { Text } from '@/components/ui/Text';
import { toneStyles, type Tone } from '@/theme/tokens';

export interface BadgeProps {
  label: string;
  tone?: Tone;
  /** A short glyph shown next to the label so state never depends on colour alone. */
  glyph?: string;
}

export function Badge({ label, tone = 'neutral', glyph }: BadgeProps) {
  const style = toneStyles[tone];

  return (
    <View
      accessible
      accessibilityLabel={label}
      className={`flex-row items-center gap-1 self-start rounded-full border px-2.5 py-1 ${style.container}`}
    >
      <Text className={`text-xs font-bold ${style.text}`}>{glyph ?? style.icon}</Text>
      <Text className={`text-xs font-semibold ${style.text}`}>{label}</Text>
    </View>
  );
}
