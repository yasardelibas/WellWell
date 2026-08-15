import { useRouter } from 'expo-router';

import { Button } from '@/components/ui/Button';
import { EmptyState, Screen } from '@/components/ui/Screen';

export default function NotFound() {
  const router = useRouter();

  return (
    <Screen className="justify-center">
      <EmptyState
        icon="help-circle-outline"
        title="This screen does not exist"
        description="The link you followed is not part of MedGuard."
        action={<Button label="Go to home" size="md" onPress={() => router.replace('/(tabs)')} />}
      />
    </Screen>
  );
}
