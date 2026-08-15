import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import {
  ActivityIndicator,
  Pressable,
  RefreshControl,
  ScrollView,
  View,
  type ScrollViewProps,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Button } from '@/components/ui/Button';
import { Text } from '@/components/ui/Text';
import { palette } from '@/theme/tokens';

export interface ScreenProps extends ScrollViewProps {
  children: React.ReactNode;
  /** Screens that render their own scroll container (lists, camera) opt out. */
  scroll?: boolean;
  refreshing?: boolean;
  onRefresh?: () => void;
  padded?: boolean;
  className?: string;
}

export function Screen({
  children,
  scroll = true,
  refreshing,
  onRefresh,
  padded = true,
  className,
  ...props
}: ScreenProps) {
  const insets = useSafeAreaInsets();
  const padding = padded ? 'px-5' : '';

  if (!scroll) {
    return <View className={`flex-1 bg-canvas ${padding} ${className ?? ''}`}>{children}</View>;
  }

  return (
    <ScrollView
      className={`flex-1 bg-canvas ${padding} ${className ?? ''}`}
      contentContainerStyle={{ paddingBottom: insets.bottom + 32, gap: 16 }}
      keyboardShouldPersistTaps="handled"
      refreshControl={
        onRefresh ? <RefreshControl refreshing={refreshing ?? false} onRefresh={onRefresh} tintColor={palette.brand} /> : undefined
      }
      {...props}
    >
      {children}
    </ScrollView>
  );
}

export function ScreenHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <View className="flex-row items-start justify-between gap-4 pt-2">
      <View className="flex-1">
        <Text variant="title" accessibilityRole="header">
          {title}
        </Text>
        {subtitle ? <Text className="mt-1 text-ink-muted">{subtitle}</Text> : null}
      </View>
      {action}
    </View>
  );
}

export function BackLink({ label = 'Back' }: { label?: string }) {
  const router = useRouter();

  return (
    <Pressable
      onPress={() => (router.canGoBack() ? router.back() : router.replace('/(tabs)'))}
      accessibilityRole="button"
      accessibilityLabel={label}
      className="mt-2 flex-row items-center gap-1 self-start py-1"
    >
      <Ionicons name="chevron-back" size={18} color={palette.brand} />
      <Text className="font-semibold text-brand-600">{label}</Text>
    </Pressable>
  );
}

export function LoadingState({ label = 'Loading' }: { label?: string }) {
  return (
    <View className="items-center justify-center gap-3 py-16" accessibilityRole="progressbar" accessibilityLabel={label}>
      <ActivityIndicator color={palette.brand} />
      <Text variant="caption">{label}…</Text>
    </View>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <View className="items-center gap-3 rounded-3xl border border-line bg-surface p-6">
      <Ionicons name="cloud-offline-outline" size={28} color={palette.inkMuted} />
      <Text className="text-center text-ink-muted">{message}</Text>
      {onRetry ? <Button label="Try again" variant="secondary" size="md" onPress={onRetry} /> : null}
    </View>
  );
}

export function EmptyState({
  icon = 'file-tray-outline',
  title,
  description,
  action,
}: {
  icon?: keyof typeof Ionicons.glyphMap;
  title: string;
  description: string;
  action?: React.ReactNode;
}) {
  return (
    <View className="items-center gap-3 rounded-3xl border border-dashed border-line bg-surface p-8">
      <Ionicons name={icon} size={30} color={palette.inkSubtle} />
      <Text variant="heading" className="text-center">
        {title}
      </Text>
      <Text className="text-center text-ink-muted">{description}</Text>
      {action}
    </View>
  );
}
