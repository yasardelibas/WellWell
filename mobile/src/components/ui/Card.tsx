import { Pressable, View, type ViewProps } from 'react-native';

import { Text } from '@/components/ui/Text';

export interface CardProps extends ViewProps {
  className?: string;
}

export function Card({ className, ...props }: CardProps) {
  return <View {...props} className={`rounded-3xl border border-line bg-surface p-4 ${className ?? ''}`} />;
}

export interface PressableCardProps {
  onPress: () => void;
  accessibilityLabel: string;
  accessibilityHint?: string;
  children: React.ReactNode;
  className?: string;
}

export function PressableCard({
  onPress,
  accessibilityLabel,
  accessibilityHint,
  children,
  className,
}: PressableCardProps) {
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      accessibilityHint={accessibilityHint}
      className={`rounded-3xl border border-line bg-surface p-4 active:bg-surface-muted ${className ?? ''}`}
    >
      {children}
    </Pressable>
  );
}

export function SectionHeader({ title, action }: { title: string; action?: React.ReactNode }) {
  return (
    <View className="mb-3 flex-row items-center justify-between">
      <Text variant="heading" accessibilityRole="header">
        {title}
      </Text>
      {action}
    </View>
  );
}

export function FieldRow({
  label,
  value,
  divider = true,
}: {
  label: string;
  value: string | null | undefined;
  divider?: boolean;
}) {
  return (
    <View className={`flex-row items-start justify-between gap-4 py-3 ${divider ? 'border-b border-line' : ''}`}>
      <Text variant="label" className="flex-1">
        {label}
      </Text>
      <Text className="flex-1 text-right">{value && value.length > 0 ? value : '—'}</Text>
    </View>
  );
}
