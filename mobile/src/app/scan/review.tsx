import { Ionicons } from '@expo/vector-icons';
import { useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import { useMemo, useState } from 'react';
import { Pressable, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import {
  IngredientEditor,
  emptyIngredient,
  toIngredientInputs,
  type EditableIngredient,
} from '@/components/medications/IngredientEditor';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { Card, FieldRow } from '@/components/ui/Card';
import { BackLink, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { useScanStore } from '@/features/scanner/store';
import { ApiError, describeError } from '@/services/api/client';
import { scanApi } from '@/services/api/endpoints';
import { config } from '@/services/config';
import { queryKeys } from '@/services/query';
import { palette } from '@/theme/tokens';
import { formatConfidence } from '@/utils/format';
import type { MedicationCandidate, ScanResponse } from '@/types/api';

export default function ScanReview() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const queryClient = useQueryClient();
  const scan = useScanStore((state) => state.scan);
  const setOutcome = useScanStore((state) => state.setOutcome);

  const [editing, setEditing] = useState(false);
  const [selectedRxCui, setSelectedRxCui] = useState<string | null>(scan?.candidates[0]?.rxCui ?? null);
  const [draft, setDraft] = useState(() => buildDraft(scan, scan?.candidates[0]));
  const [acknowledgeUnverified, setAcknowledgeUnverified] = useState(false);
  const [needsAcknowledgement, setNeedsAcknowledgement] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const lowConfidence = useMemo(
    () => (scan ? scan.extractionConfidence < config.manualReviewThreshold : false),
    [scan],
  );

  if (!scan) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink label="Scanner" />
        <Callout tone="info" title="Nothing to review" message="Scan a medication label to see the extracted details." />
        <Button label="Open the scanner" onPress={() => router.replace('/(tabs)/scan')} />
      </Screen>
    );
  }

  if (scan.status === 'extraction_failed') {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink label="Scanner" />
        <Callout tone="attention" title="We couldn't read the label clearly" message={scan.message} />
        <Button label="Try again" onPress={() => router.replace('/(tabs)/scan')} />
        <Button label="Enter the details manually" variant="secondary" onPress={() => router.replace('/medication/new')} />
      </Screen>
    );
  }

  function applyCandidate(candidate: MedicationCandidate) {
    setSelectedRxCui(candidate.rxCui);
    setDraft(buildDraft(scan, candidate));
  }

  async function confirm(acknowledged: boolean) {
    setBusy(true);
    setError(null);

    try {
      const outcome = await scanApi.confirm(scan!.scanId, {
        selectedCandidateRxCui: selectedRxCui,
        brandName: draft.brandName.trim() || null,
        genericName: draft.genericName.trim() || null,
        ingredients: toIngredientInputs(draft.ingredients),
        dosageForm: draft.dosageForm.trim() || null,
        strength: draft.strength.trim() || null,
        route: draft.route.trim() || null,
        labelDirections: draft.directions.trim() || null,
        acknowledgedUnverified: acknowledged,
      });

      setOutcome(outcome);
      await queryClient.invalidateQueries({ queryKey: queryKeys.medications });
      await queryClient.invalidateQueries({ queryKey: queryKeys.safetyFindings });
      router.replace('/scan/result');
    } catch (caught) {
      if (caught instanceof ApiError && caught.code === 'unverified_requires_acknowledgement') {
        setNeedsAcknowledgement(true);
        setError(caught.message);
      } else {
        setError(describeError(caught));
      }
    } finally {
      setBusy(false);
    }
  }

  const verified = scan.verificationStatus === 'verified';

  return (
    <Screen style={{ paddingTop: insets.top }}>
      <BackLink label="Scanner" />

      <View className="gap-1">
        <Text variant="title">We found this medication</Text>
        <Text className="text-ink-muted">{scan.message}</Text>
      </View>

      {lowConfidence ? (
        <Callout
          tone="attention"
          title="Please review the details"
          message={`The label was read with ${formatConfidence(scan.extractionConfidence)} confidence. Check every field against the label before confirming.`}
        />
      ) : null}

      <Card className="gap-1">
        <View className="mb-2 flex-row items-center justify-between">
          <Text variant="heading">Medication details</Text>
          <Pressable
            onPress={() => setEditing((value) => !value)}
            accessibilityRole="button"
            accessibilityLabel={editing ? 'Stop editing' : 'Edit information'}
            className="flex-row items-center gap-1 py-1"
          >
            <Ionicons name={editing ? 'checkmark' : 'create-outline'} size={16} color={palette.brand} />
            <Text className="font-semibold text-brand-600">{editing ? 'Done' : 'Edit'}</Text>
          </Pressable>
        </View>

        {editing ? (
          <View className="gap-3">
            <EditRow label="Brand" value={draft.brandName} onChange={(value) => setDraft({ ...draft, brandName: value })} />
            <EditRow
              label="Generic name"
              value={draft.genericName}
              onChange={(value) => setDraft({ ...draft, genericName: value })}
            />
            <EditRow
              label="Dosage form"
              value={draft.dosageForm}
              onChange={(value) => setDraft({ ...draft, dosageForm: value })}
            />
            <EditRow label="Strength" value={draft.strength} onChange={(value) => setDraft({ ...draft, strength: value })} />
            <EditRow label="Route" value={draft.route} onChange={(value) => setDraft({ ...draft, route: value })} />
            <EditRow
              label="Label directions"
              value={draft.directions}
              onChange={(value) => setDraft({ ...draft, directions: value })}
              multiline
            />
            <IngredientEditor
              ingredients={draft.ingredients}
              onChange={(ingredients) => setDraft({ ...draft, ingredients })}
            />
          </View>
        ) : (
          <>
            <FieldRow label="Brand" value={draft.brandName} />
            <FieldRow label="Generic name" value={draft.genericName} />
            <FieldRow
              label="Active ingredients"
              value={draft.ingredients
                .filter((ingredient) => ingredient.name.length > 0)
                .map((ingredient) => `${ingredient.name} ${ingredient.strength} ${ingredient.unit}`.trim())
                .join('\n')}
            />
            <FieldRow label="Dosage form" value={draft.dosageForm} />
            <FieldRow label="Strength" value={draft.strength} />
            <FieldRow label="Label directions" value={draft.directions} divider={false} />
          </>
        )}
      </Card>

      <Card className="gap-3">
        <Text variant="heading">Verification</Text>
        {verified ? (
          <>
            <Badge label="Verified against a trusted medication database" tone="safe" glyph="✓" />
            {scan.candidates[0]?.provenance ? (
              <Text variant="caption">
                Source: {scan.candidates[0].provenance.provider}
                {scan.candidates[0].provenance.datasetVersion
                  ? ` · dataset ${scan.candidates[0].provenance.datasetVersion}`
                  : ''}
              </Text>
            ) : null}
          </>
        ) : (
          <>
            <Badge label="Not independently verified" tone="attention" glyph="?" />
            <Text className="text-sm text-ink-muted">
              MedGuard could not confirm this product against its medication data source. You can still save it, and it
              will stay marked as unverified.
            </Text>
          </>
        )}
      </Card>

      {scan.candidates.length > 0 ? (
        <Card className="gap-3">
          <Text variant="heading">Candidate matches</Text>
          <Text variant="caption">Choose the product that matches the label in your hand.</Text>
          {scan.candidates.map((candidate) => {
            const selected = candidate.rxCui === selectedRxCui;

            return (
              <Pressable
                key={`${candidate.rxCui}-${candidate.brandName}`}
                onPress={() => applyCandidate(candidate)}
                accessibilityRole="radio"
                accessibilityState={{ selected }}
                accessibilityLabel={`${candidate.brandName}, ${candidate.genericName}`}
                className={`gap-1 rounded-2xl border p-3 ${selected ? 'border-brand-500 bg-brand-50' : 'border-line bg-surface'}`}
              >
                <View className="flex-row items-center justify-between gap-2">
                  <Text className="flex-1 font-semibold">{candidate.brandName}</Text>
                  {selected ? <Ionicons name="checkmark-circle" size={20} color={palette.brand} /> : null}
                </View>
                <Text className="text-sm text-ink-muted">
                  {candidate.genericName}
                  {candidate.strength ? ` · ${candidate.strength}` : ''}
                  {candidate.dosageForm ? ` · ${candidate.dosageForm}` : ''}
                </Text>
                <Text variant="caption">
                  Match {formatConfidence(candidate.matchScore)} · {candidate.provenance.provider}
                </Text>
              </Pressable>
            );
          })}
        </Card>
      ) : null}

      {needsAcknowledgement ? (
        <Callout tone="attention" title="Save as unverified?" message={error ?? undefined}>
          <Pressable
            onPress={() => setAcknowledgeUnverified((value) => !value)}
            accessibilityRole="checkbox"
            accessibilityState={{ checked: acknowledgeUnverified }}
            accessibilityLabel="I understand this medication is not independently verified"
            className="mt-1 flex-row items-center gap-3 py-2"
          >
            <View
              className={`h-6 w-6 items-center justify-center rounded-md border ${
                acknowledgeUnverified ? 'border-attention-500 bg-attention-500' : 'border-attention-500/50'
              }`}
            >
              {acknowledgeUnverified ? <Ionicons name="checkmark" size={16} color="#FFFFFF" /> : null}
            </View>
            <Text className="flex-1 text-sm text-attention-700">
              I understand this medication is not independently verified and I checked the details against the label.
            </Text>
          </Pressable>
        </Callout>
      ) : error ? (
        <Text className="text-sm text-critical-700">{error}</Text>
      ) : null}

      <View className="gap-3">
        <Button
          label={needsAcknowledgement ? 'Save as unverified' : 'Confirm medication'}
          loading={busy}
          disabled={needsAcknowledgement && !acknowledgeUnverified}
          onPress={() => void confirm(needsAcknowledgement ? acknowledgeUnverified : false)}
        />
        <Button label="Edit information" variant="secondary" onPress={() => setEditing(true)} />
        <Button label="Scan again" variant="ghost" onPress={() => router.replace('/(tabs)/scan')} />
      </View>
    </Screen>
  );
}

interface Draft {
  brandName: string;
  genericName: string;
  dosageForm: string;
  strength: string;
  route: string;
  directions: string;
  ingredients: EditableIngredient[];
}

function buildDraft(scan: ScanResponse | null, candidate?: MedicationCandidate): Draft {
  const extraction = scan?.extraction;

  const ingredients: EditableIngredient[] = candidate
    ? candidate.ingredients.map((ingredient) => ({
        name: ingredient.name,
        strength: ingredient.strength != null ? String(ingredient.strength) : '',
        unit: ingredient.unit ?? '',
      }))
    : (extraction?.activeIngredients ?? []).map((ingredient) => ({
        name: ingredient.name.value ?? '',
        strength: ingredient.strength?.value ?? '',
        unit: ingredient.unit?.value ?? '',
      }));

  return {
    brandName: candidate?.brandName ?? extraction?.brandName.value ?? '',
    genericName: candidate?.genericName ?? extraction?.genericName.value ?? '',
    dosageForm: candidate?.dosageForm ?? extraction?.dosageForm.value ?? '',
    strength: candidate?.strength ?? '',
    route: extraction?.route.value ?? '',
    directions: extraction?.directions.value ?? '',
    ingredients: ingredients.length > 0 ? ingredients : [emptyIngredient()],
  };
}

function EditRow({
  label,
  value,
  onChange,
  multiline = false,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  multiline?: boolean;
}) {
  return (
    <View className="gap-1.5">
      <Text variant="label">{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChange}
        accessibilityLabel={label}
        multiline={multiline}
        placeholderTextColor={palette.inkSubtle}
        className={`rounded-2xl border border-line bg-surface px-4 py-3 text-base text-ink ${multiline ? 'min-h-20' : 'min-h-12'}`}
      />
    </View>
  );
}
