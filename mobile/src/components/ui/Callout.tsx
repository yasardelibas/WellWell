import { Ionicons } from '@expo/vector-icons';
import { View } from 'react-native';

import { Text } from '@/components/ui/Text';
import { toneStyles, type Tone } from '@/theme/tokens';

const icons: Record<Tone, keyof typeof Ionicons.glyphMap> = {
  neutral: 'information-circle-outline',
  info: 'information-circle-outline',
  safe: 'checkmark-circle-outline',
  attention: 'alert-circle-outline',
  critical: 'warning-outline',
};

export interface CalloutProps {
  tone?: Tone;
  title: string;
  children?: React.ReactNode;
  message?: string;
}

export function Callout({ tone = 'info', title, message, children }: CalloutProps) {
  const style = toneStyles[tone];

  return (
    <View className={`gap-2 rounded-3xl border p-4 ${style.container}`}>
      <View className="flex-row items-center gap-2">
        <Ionicons name={icons[tone]} size={20} color={style.color} />
        <Text className={`flex-1 text-base font-semibold ${style.text}`} accessibilityRole="header">
          {title}
        </Text>
      </View>
      {message ? <Text className={`${style.text} text-sm`}>{message}</Text> : null}
      {children}
    </View>
  );
}
