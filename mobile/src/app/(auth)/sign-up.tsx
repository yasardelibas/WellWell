import { useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { KeyboardAvoidingView, Platform, ScrollView, View } from 'react-native';

import { BackLink } from '@/components/ui/Screen';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { SafeAreaView } from '@/components/ui/SafeAreaView';
import { Text } from '@/components/ui/Text';
import { TextField } from '@/components/ui/TextField';
import { signUpSchema, type SignUpValues } from '@/features/auth/schemas';
import { describeError } from '@/services/api/client';
import { useAuthStore } from '@/store/auth';
import { zodValidator } from '@/utils/form';

export default function SignUp() {
  const signUp = useAuthStore((state) => state.signUp);
  const [error, setError] = useState<string | null>(null);

  const { control, handleSubmit, formState } = useForm<SignUpValues>({
    resolver: zodValidator(signUpSchema),
    defaultValues: { displayName: '', email: '', password: '' },
  });

  const submit = handleSubmit(async (values) => {
    setError(null);

    try {
      await signUp(values);
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
            <Text variant="title">Create your account</Text>
            <Text className="text-ink-muted">Your medication list stays private to you unless you choose to share it.</Text>
          </View>

          <View className="gap-4">
            <Controller
              control={control}
              name="displayName"
              render={({ field, fieldState }) => (
                <TextField
                  label="Name"
                  value={field.value}
                  onChangeText={field.onChange}
                  onBlur={field.onBlur}
                  error={fieldState.error?.message}
                  autoComplete="name"
                  textContentType="name"
                  placeholder="How should we greet you?"
                />
              )}
            />

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
                  hint="At least 10 characters, mixing letters and numbers."
                  secure
                  autoCapitalize="none"
                  autoComplete="new-password"
                  textContentType="newPassword"
                  placeholder="Create a password"
                />
              )}
            />
          </View>

          {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

          <Callout
            tone="info"
            title="What MedGuard does not do"
            message="MedGuard never diagnoses conditions or changes the instructions on your medication label."
          />

          <Button label="Create account" loading={formState.isSubmitting} onPress={() => void submit()} />
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
