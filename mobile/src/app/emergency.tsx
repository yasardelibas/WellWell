import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import { Alert, Pressable, Switch, View } from 'react-native';
import QRCode from 'react-native-qrcode-svg';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { Card } from '@/components/ui/Card';
import { BackLink, ErrorState, LoadingState, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { TextField } from '@/components/ui/TextField';
import { useEmergencyCard, useRegenerateEmergencyToken, useUpdateEmergencyCard } from '@/features/emergency/hooks';
import { describeError } from '@/services/api/client';
import { palette } from '@/theme/tokens';
import { formatDateTime } from '@/utils/format';
import type { EmergencyCard, UpdateEmergencyCardRequest } from '@/types/api';

export default function EmergencyCardScreen() {
  const insets = useSafeAreaInsets();
  const card = useEmergencyCard();
  const update = useUpdateEmergencyCard();
  const regenerate = useRegenerateEmergencyToken();

  const [edits, setDraft] = useState<UpdateEmergencyCardRequest | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  const draft = edits ?? (card.data ? toEditableCard(card.data) : null);

  async function save() {
    if (!draft) {
      return;
    }

    setError(null);
    setSaved(false);

    try {
      await update.mutateAsync(draft);
      setSaved(true);
    } catch (caught) {
      setError(describeError(caught));
    }
  }

  function confirmRegenerate() {
    Alert.alert(
      'Create a new QR code?',
      'The previous QR code and link stop working immediately. Anyone holding a printed copy will no longer see your card.',
      [
        { text: 'Keep the current one', style: 'cancel' },
        {
          text: 'Create new',
          style: 'destructive',
          onPress: () => {
            void regenerate.mutateAsync().catch((caught: unknown) => setError(describeError(caught)));
          },
        },
      ],
    );
  }

  if (card.isPending) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink />
        <LoadingState label="Loading your emergency card" />
      </Screen>
    );
  }

  if (card.isError || !card.data || !draft) {
    return (
      <Screen style={{ paddingTop: insets.top }}>
        <BackLink />
        <ErrorState message={describeError(card.error)} onRetry={() => void card.refetch()} />
      </Screen>
    );
  }

  const enabled = draft.isEnabled;

  return (
    <Screen style={{ paddingTop: insets.top }}>
      <BackLink />

      <View className="gap-1">
        <Text variant="title">Emergency card</Text>
        <Text className="text-ink-muted">
          Share only what you choose. The QR code holds a random link, never your medical information.
        </Text>
      </View>

      <Card className="gap-3">
        <ToggleRow
          label="Emergency card is active"
          hint="Turn this off to make the link stop working."
          value={enabled}
          onChange={(value) => setDraft({ ...draft, isEnabled: value })}
        />
      </Card>

      {enabled ? (
        <Card className="items-center gap-3 py-6">
          <View className="rounded-3xl bg-white p-4" accessibilityLabel="Emergency card QR code">
            <QRCode value={card.data.shareUrl} size={190} color={palette.ink} backgroundColor="#FFFFFF" />
          </View>
          <Text variant="caption" className="text-center">
            {card.data.shareUrl}
          </Text>
          <Text variant="caption" className="text-center">
            Last updated {formatDateTime(card.data.updatedAt)}
            {card.data.tokenExpiresAt ? ` · expires ${formatDateTime(card.data.tokenExpiresAt)}` : ''}
          </Text>
        </Card>
      ) : (
        <Callout
          tone="neutral"
          title="The card is switched off"
          message="Nobody can open the link while the card is inactive."
        />
      )}

      <Card className="gap-3">
        <Text variant="heading">What is shared</Text>
        <ToggleRow label="Name" value={draft.shareName} onChange={(value) => setDraft({ ...draft, shareName: value })} />
        <ToggleRow
          label="Allergies"
          value={draft.shareAllergies}
          onChange={(value) => setDraft({ ...draft, shareAllergies: value })}
        />
        <ToggleRow
          label="Active medications"
          value={draft.shareMedications}
          onChange={(value) => setDraft({ ...draft, shareMedications: value })}
        />
        <ToggleRow
          label="Emergency contact"
          value={draft.shareEmergencyContact}
          onChange={(value) => setDraft({ ...draft, shareEmergencyContact: value })}
        />
        <ToggleRow label="Notes" value={draft.shareNotes} onChange={(value) => setDraft({ ...draft, shareNotes: value })} />
      </Card>

      <Card className="gap-4">
        <Text variant="heading">Card details</Text>
        <TextField
          label="Name shown"
          value={draft.displayName ?? ''}
          onChangeText={(value) => setDraft({ ...draft, displayName: value })}
          placeholder="The name responders should see"
        />
        <TextField
          label="Allergies"
          value={draft.allergies ?? ''}
          onChangeText={(value) => setDraft({ ...draft, allergies: value })}
          placeholder="Penicillin"
          multiline
        />
        <TextField
          label="Emergency contact name"
          value={draft.emergencyContactName ?? ''}
          onChangeText={(value) => setDraft({ ...draft, emergencyContactName: value })}
          placeholder="Who should be called"
        />
        <TextField
          label="Emergency contact phone"
          value={draft.emergencyContactPhone ?? ''}
          onChangeText={(value) => setDraft({ ...draft, emergencyContactPhone: value })}
          placeholder="+90 555 000 00 00"
          keyboardType="phone-pad"
        />
        <TextField
          label="Important notes"
          value={draft.notes ?? ''}
          onChangeText={(value) => setDraft({ ...draft, notes: value })}
          placeholder="Anything responders should know"
          multiline
        />
      </Card>

      {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}
      {saved ? <Text className="text-sm text-safe-700">Your emergency card was updated.</Text> : null}

      <View className="gap-3">
        <Button label="Save card" loading={update.isPending} onPress={() => void save()} />
        <Button
          label="Create a new QR code"
          variant="secondary"
          loading={regenerate.isPending}
          icon={<Ionicons name="refresh-outline" size={18} color={palette.ink} />}
          onPress={confirmRegenerate}
        />
      </View>

      <Callout
        tone="info"
        title="How the QR code works"
        message="The code points to a random, revocable link. Opening it shows only the fields you switched on, and never your account details."
      />
    </Screen>
  );
}

function toEditableCard(card: EmergencyCard): UpdateEmergencyCardRequest {
  const { shareUrl: _shareUrl, tokenIssuedAt: _issuedAt, tokenExpiresAt: _expiresAt, updatedAt: _updatedAt, ...editable } = card;
  return editable;
}

function ToggleRow({
  label,
  hint,
  value,
  onChange,
}: {
  label: string;
  hint?: string;
  value: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <Pressable
      onPress={() => onChange(!value)}
      accessibilityRole="switch"
      accessibilityState={{ checked: value }}
      accessibilityLabel={label}
      className="flex-row items-center justify-between gap-4 py-1"
    >
      <View className="flex-1">
        <Text className="font-medium">{label}</Text>
        {hint ? <Text variant="caption">{hint}</Text> : null}
      </View>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ true: palette.brand, false: palette.line }}
        thumbColor="#FFFFFF"
      />
    </Pressable>
  );
}
