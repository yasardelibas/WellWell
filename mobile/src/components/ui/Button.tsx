import { ActivityIndicator, Pressable, type PressableProps, View } from 'react-native';

import { Text } from '@/components/ui/Text';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';
type Size = 'md' | 'lg';

const containers: Record<Variant, string> = {
  primary: 'bg-brand-500 active:bg-brand-600 border-brand-500',
  secondary: 'bg-surface active:bg-surface-muted border-line',
  ghost: 'bg-transparent active:bg-surface-muted border-transparent',
  danger: 'bg-critical-50 active:bg-critical-500/15 border-critical-500/40',
};

const labels: Record<Variant, string> = {
  primary: 'text-white',
  secondary: 'text-ink',
  ghost: 'text-brand-600',
  danger: 'text-critical-700',
};

const sizes: Record<Size, string> = {
  md: 'min-h-11 px-4 py-2.5',
  lg: 'min-h-14 px-5 py-3.5',
};

export interface ButtonProps extends Omit<PressableProps, 'children' | 'style'> {
  label: string;
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  icon?: React.ReactNode;
  className?: string;
}

export function Button({
  label,
  variant = 'primary',
  size = 'lg',
  loading = false,
  icon,
  disabled,
  className,
  ...props
}: ButtonProps) {
  const isDisabled = disabled === true || loading;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: isDisabled, busy: loading }}
      accessibilityLabel={label}
      disabled={isDisabled}
      className={`flex-row items-center justify-center gap-2 rounded-2xl border ${containers[variant]} ${sizes[size]} ${
        isDisabled ? 'opacity-50' : ''
      } ${className ?? ''}`}
      {...props}
    >
      {loading ? <ActivityIndicator size="small" color={variant === 'primary' ? '#FFFFFF' : '#2F6FED'} /> : icon}
      <Text className={`text-center text-base font-semibold ${labels[variant]}`}>{label}</Text>
    </Pressable>
  );
}

/** Full-width action row used at the bottom of decision screens. */
export function ButtonGroup({ children }: { children: React.ReactNode }) {
  return <View className="gap-3">{children}</View>;
}
