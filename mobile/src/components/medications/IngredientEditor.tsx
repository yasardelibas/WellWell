import { Ionicons } from '@expo/vector-icons';
import { Pressable, TextInput, View } from 'react-native';

import { Text } from '@/components/ui/Text';
import { palette } from '@/theme/tokens';

export interface EditableIngredient {
  name: string;
  strength: string;
  unit: string;
}

export function emptyIngredient(): EditableIngredient {
  return { name: '', strength: '', unit: 'mg' };
}

export interface IngredientEditorProps {
  ingredients: EditableIngredient[];
  onChange: (ingredients: EditableIngredient[]) => void;
}

/**
 * Active ingredients drive the duplicate check, so they stay fully editable and are never
 * silently corrected on the user's behalf.
 */
export function IngredientEditor({ ingredients, onChange }: IngredientEditorProps) {
  function update(index: number, patch: Partial<EditableIngredient>) {
    onChange(ingredients.map((item, position) => (position === index ? { ...item, ...patch } : item)));
  }

  return (
    <View className="gap-3">
      <Text variant="label">Active ingredients</Text>

      {ingredients.map((ingredient, index) => (
        <View key={index} className="gap-2 rounded-2xl border border-line bg-surface p-3">
          <View className="flex-row items-center gap-2">
            <TextInput
              value={ingredient.name}
              onChangeText={(value) => update(index, { name: value })}
              accessibilityLabel={`Ingredient ${index + 1} name`}
              placeholder="Ingredient name"
              placeholderTextColor={palette.inkSubtle}
              className="min-h-11 flex-1 rounded-xl bg-surface-muted px-3 text-base text-ink"
            />
            {ingredients.length > 1 ? (
              <Pressable
                onPress={() => onChange(ingredients.filter((_, position) => position !== index))}
                accessibilityRole="button"
                accessibilityLabel={`Remove ingredient ${index + 1}`}
                className="h-11 w-11 items-center justify-center rounded-xl border border-line"
              >
                <Ionicons name="trash-outline" size={18} color={palette.inkMuted} />
              </Pressable>
            ) : null}
          </View>

          <View className="flex-row gap-2">
            <TextInput
              value={ingredient.strength}
              onChangeText={(value) => update(index, { strength: value })}
              accessibilityLabel={`Ingredient ${index + 1} strength`}
              placeholder="Strength"
              keyboardType="decimal-pad"
              placeholderTextColor={palette.inkSubtle}
              className="min-h-11 flex-1 rounded-xl bg-surface-muted px-3 text-base text-ink"
            />
            <TextInput
              value={ingredient.unit}
              onChangeText={(value) => update(index, { unit: value })}
              accessibilityLabel={`Ingredient ${index + 1} unit`}
              placeholder="Unit"
              autoCapitalize="none"
              placeholderTextColor={palette.inkSubtle}
              className="min-h-11 w-24 rounded-xl bg-surface-muted px-3 text-base text-ink"
            />
          </View>
        </View>
      ))}

      <Pressable
        onPress={() => onChange([...ingredients, emptyIngredient()])}
        accessibilityRole="button"
        accessibilityLabel="Add another ingredient"
        className="min-h-11 flex-row items-center justify-center gap-2 rounded-2xl border border-dashed border-line active:bg-surface-muted"
      >
        <Ionicons name="add" size={18} color={palette.brand} />
        <Text className="font-semibold text-brand-600">Add ingredient</Text>
      </Pressable>
    </View>
  );
}

export function toIngredientInputs(ingredients: EditableIngredient[]) {
  return ingredients
    .filter((ingredient) => ingredient.name.trim().length > 0)
    .map((ingredient) => {
      const strength = Number.parseFloat(ingredient.strength.replace(',', '.'));

      return {
        name: ingredient.name.trim(),
        strength: Number.isFinite(strength) ? strength : null,
        unit: ingredient.unit.trim().length > 0 ? ingredient.unit.trim() : null,
        rxCui: null,
      };
    });
}
