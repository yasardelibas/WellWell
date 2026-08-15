import { useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { KeyboardAvoidingView, Platform, ScrollView, View } from 'react-native';

import { BackLink } from '@/components/ui/Screen';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { SafeAreaView } from '@/components/ui/SafeAreaView';
import { Text } from '@/components/ui/Text';
import { TextField } from '@/components/ui/TextField';
import { forgotPasswordSchema, type ForgotPasswordValues } from '@/features/auth/schemas';
import { authApi } from '@/services/api/endpoints';
import { describeError } from '@/services/api/client';
import { zodValidator } from '@/utils/form';

export default function ForgotPassword() {
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { control, handleSubmit, formState } = useForm<ForgotPasswordValues>({
    resolver: zodValidator(forgotPasswordSchema),
    defaultValues: { email: '' },
  });

  const submit = handleSubmit(async (values) => {
    setError(null);

    try {
      await authApi.forgotPassword({ email: values.email });
      setSent(true);
    } catch (caught) {
      setError(describeError(caught));
    }
  });

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <KeyboardAvoidingView className="flex-1" behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 20 }}>
          <BackLink label="Sign in" />

          <View className="gap-2">
            <Text variant="title">Reset your password</Text>
            <Text className="text-ink-muted">
              Enter your email address and we&apos;ll send a reset link if an account exists.
            </Text>
          </View>

          {sent ? (
            <Callout
              tone="safe"
              title="Check your email"
              message="If an account exists for that address, a reset link is on its way. The link expires shortly for your security."
            />
          ) : (
            <>
              <Controller
                control={control}
                name="email"
                render={({ field, fieldState }) => (
                  <TextField
                    label="Email"
                    value={field.value}
                    onChangeText={field.onChange}
                    onBlur={field.onBlur}
                    error={fieldState.error?.message}
                    autoCapitalize="none"
                    autoComplete="email"
                    keyboardType="email-address"
                    placeholder="you@example.com"
                  />
                )}
              />

              {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

              <Button label="Send reset link" loading={formState.isSubmitting} onPress={() => void submit()} />
            </>
          )}
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
