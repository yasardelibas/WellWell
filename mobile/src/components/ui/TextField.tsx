import { useState } from 'react';
import { Pressable, TextInput, View, type TextInputProps } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Text } from '@/components/ui/Text';
import { palette } from '@/theme/tokens';

export interface TextFieldProps extends Omit<TextInputProps, 'className'> {
  label: string;
  error?: string;
  hint?: string;
  secure?: boolean;
}

export function TextField({ label, error, hint, secure = false, ...props }: TextFieldProps) {
  const [revealed, setRevealed] = useState(false);

  return (
    <View className="gap-1.5">
      <Text variant="label">{label}</Text>
      <View
        className={`flex-row items-center rounded-2xl border bg-surface px-4 ${
          error ? 'border-critical-500' : 'border-line'
        }`}
      >
        <TextInput
          accessibilityLabel={label}
          placeholderTextColor={palette.inkSubtle}
          secureTextEntry={secure && !revealed}
          className="min-h-12 flex-1 py-3 text-base text-ink"
          {...props}
        />
        {secure ? (
          <Pressable
            onPress={() => setRevealed((value) => !value)}
            accessibilityRole="button"
            accessibilityLabel={revealed ? 'Hide password' : 'Show password'}
            className="p-2"
          >
            <Ionicons name={revealed ? 'eye-off-outline' : 'eye-outline'} size={20} color={palette.inkMuted} />
          </Pressable>
        ) : null}
      </View>
      {error ? (
        <Text className="text-xs font-medium text-critical-700">{error}</Text>
      ) : hint ? (
        <Text variant="caption">{hint}</Text>
      ) : null}
    </View>
  );
}
