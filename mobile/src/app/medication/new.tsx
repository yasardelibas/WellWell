import { useRouter } from 'expo-router';
import { useState } from 'react';
import { View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import {
  IngredientEditor,
  emptyIngredient,
  toIngredientInputs,
  type EditableIngredient,
} from '@/components/medications/IngredientEditor';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { Card } from '@/components/ui/Card';
import { BackLink, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { TextField } from '@/components/ui/TextField';
import { useCreateMedication } from '@/features/medications/hooks';
import { useRunSafetyAnalysis } from '@/features/safety/hooks';
import { describeError } from '@/services/api/client';

export default function NewMedication() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const create = useCreateMedication();
  const analyse = useRunSafetyAnalysis();

  const [brandName, setBrandName] = useState('');
  const [genericName, setGenericName] = useState('');
  const [dosageForm, setDosageForm] = useState('');
  const [strength, setStrength] = useState('');
  const [directions, setDirections] = useState('');
  const [ingredients, setIngredients] = useState<EditableIngredient[]>([emptyIngredient()]);
  const [error, setError] = useState<string | null>(null);

  async function save() {
    if (brandName.trim().length === 0 && genericName.trim().length === 0) {
      setError('Add a brand name or a generic name.');
      return;
    }

    setError(null);

    try {
      const medication = await create.mutateAsync({
        brandName: brandName.trim() || null,
        genericName: genericName.trim() || null,
        ingredients: toIngredientInputs(ingredients),
        dosageForm: dosageForm.trim() || null,
        strength: strength.trim() || null,
        route: null,
        labelDirections: directions.trim() || null,
        notes: null,
        attemptVerification: true,
      });

      // Running the check straight away keeps the safety tab in step with the new entry.
      await analyse.mutateAsync(medication.id).catch(() => undefined);
      router.replace(`/medication/${medication.id}`);
    } catch (caught) {
      setError(describeError(caught));
    }
  }

  return (
    <Screen style={{ paddingTop: insets.top }}>
      <BackLink label="Medications" />

      <View className="gap-1">
        <Text variant="title">Add a medication</Text>
        <Text className="text-ink-muted">
          Copy the details from the label. MedGuard will try to match them against trusted medication data.
        </Text>
      </View>

      <Card className="gap-4">
        <TextField label="Brand name" value={brandName} onChangeText={setBrandName} placeholder="As printed on the box" />
        <TextField
          label="Generic name"
          value={genericName}
          onChangeText={setGenericName}
          placeholder="Active substance name"
        />
        <IngredientEditor ingredients={ingredients} onChange={setIngredients} />
        <TextField label="Dosage form" value={dosageForm} onChangeText={setDosageForm} placeholder="Tablet, capsule, syrup…" />
        <TextField label="Strength" value={strength} onChangeText={setStrength} placeholder="500 mg" />
        <TextField
          label="Label directions"
          value={directions}
          onChangeText={setDirections}
          placeholder="Take 1 tablet twice daily"
          multiline
        />
      </Card>

      <Callout
        tone="info"
        title="Entered by hand"
        message="If MedGuard cannot match this product, it is saved and clearly marked as unverified. Duplicate ingredient checks still run on the ingredients you entered."
      />

      {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

      <Button label="Save medication" loading={create.isPending} onPress={() => void save()} />
    </Screen>
  );
}
