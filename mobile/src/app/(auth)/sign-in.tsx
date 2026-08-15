import { Ionicons } from '@expo/vector-icons';
import { Link } from 'expo-router';
import { useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { KeyboardAvoidingView, Platform, ScrollView, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { SafeAreaView } from '@/components/ui/SafeAreaView';
import { Text } from '@/components/ui/Text';
import { TextField } from '@/components/ui/TextField';
import { signInSchema, type SignInValues } from '@/features/auth/schemas';
import { describeError } from '@/services/api/client';
import { useAuthStore } from '@/store/auth';
import { palette } from '@/theme/tokens';
import { zodValidator } from '@/utils/form';

export default function SignIn() {
  const signIn = useAuthStore((state) => state.signIn);
  const signInWithDemo = useAuthStore((state) => state.signInWithDemo);
  const sessionExpired = useAuthStore((state) => state.sessionExpired);
  const [error, setError] = useState<string | null>(null);
  const [demoLoading, setDemoLoading] = useState(false);

  const { control, handleSubmit, formState } = useForm<SignInValues>({
    resolver: zodValidator(signInSchema),
    defaultValues: { email: '', password: '' },
  });

  const submit = handleSubmit(async (values) => {
    setError(null);

    try {
      await signIn(values.email, values.password);
    } catch (caught) {
      setError(describeError(caught));
    }
  });

  async function startDemo() {
    setError(null);
    setDemoLoading(true);

    try {
      await signInWithDemo();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setDemoLoading(false);
    }
  }

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <KeyboardAvoidingView className="flex-1" behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 24, gap: 20 }}>
          <View className="gap-2">
            <View className="h-14 w-14 items-center justify-center rounded-2xl bg-brand-50">
              <Ionicons name="shield-checkmark-outline" size={28} color={palette.brand} />
            </View>
            <Text variant="title">Welcome back</Text>
            <Text className="text-ink-muted">Sign in to see your medications and today&apos;s reminders.</Text>
          </View>

          {sessionExpired ? (
            <Text className="text-sm text-attention-700">Your session ended. Please sign in again.</Text>
          ) : null}

          <View className="gap-4">
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
                  textContentType="emailAddress"
                  placeholder="you@example.com"
                />
              )}
            />

            <Controller
              control={control}
              name="password"
              render={({ field, fieldState }) => (
                <TextField
                  label="Password"
                  value={field.value}
                  onChangeText={field.onChange}
                  onBlur={field.onBlur}
                  error={fieldState.error?.message}
                  secure
                  autoCapitalize="none"
                  autoComplete="current-password"
                  textContentType="password"
                  placeholder="Your password"
                />
              )}
            />
          </View>

          {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

          <View className="gap-3">
            <Button label="Sign in" loading={formState.isSubmitting} onPress={() => void submit()} />
            <Button label="Explore the demo account" variant="secondary" loading={demoLoading} onPress={() => void startDemo()} />
          </View>

          <View className="items-center gap-2">
            <Link href="/(auth)/forgot-password" asChild>
              <Text className="font-semibold text-brand-600" accessibilityRole="link">
                Forgot your password?
              </Text>
            </Link>
            <Link href="/(auth)/sign-up" asChild>
              <Text className="font-semibold text-brand-600" accessibilityRole="link">
                Create an account
              </Text>
            </Link>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
