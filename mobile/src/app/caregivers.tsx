import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import { Alert, Pressable, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Callout } from '@/components/ui/Callout';
import { Card } from '@/components/ui/Card';
import { BackLink, EmptyState, ErrorState, LoadingState, Screen } from '@/components/ui/Screen';
import { Text } from '@/components/ui/Text';
import { TextField } from '@/components/ui/TextField';
import {
  caregiverPermissions,
  useCaregivers,
  useInviteCaregiver,
  useRevokeCaregiver,
  useUpdateCaregiverPermissions,
} from '@/features/caregiver/hooks';
import { describeError } from '@/services/api/client';
import { palette, type Tone } from '@/theme/tokens';
import { formatDateTime } from '@/utils/format';

/**
 * A relationship becomes Active only once the owner approves the permission set, so the
 * Accepted state is where the owner is expected to act rather than a state to wait out.
 */
function canApprovePermissions(status: string): boolean {
  return status === 'Accepted' || status === 'Active';
}

function describeCaregiverStatus(status: string): string {
  switch (status) {
    case 'Invited':
      return 'Invitation sent';
    case 'Accepted':
      return 'Waiting for your approval';
    case 'Active':
      return 'Active';
    case 'Declined':
      return 'Invitation declined';
    case 'Revoked':
      return 'Access removed';
    case 'Expired':
      return 'Invitation expired';
    default:
      return status;
  }
}

function caregiverStatusTone(status: string): Tone {
  switch (status) {
    case 'Active':
      return 'safe';
    case 'Accepted':
      return 'attention';
    default:
      return 'neutral';
  }
}

function caregiverStatusGlyph(status: string): string {
  switch (status) {
    case 'Active':
      return '✓';
    case 'Accepted':
      return '!';
    default:
      return '•';
  }
}

function permissionHint(status: string): string | null {
  switch (status) {
    case 'Invited':
      return 'Permissions can be approved once the caregiver accepts the invitation.';
    case 'Accepted':
      return 'This caregiver accepted the invitation. Choose what they may see to grant access.';
    case 'Active':
      return null;
    default:
      return 'This caregiver no longer has access.';
  }
}

export default function Caregivers() {
  const insets = useSafeAreaInsets();
  const caregivers = useCaregivers();
  const invite = useInviteCaregiver();
  const updatePermissions = useUpdateCaregiverPermissions();
  const revoke = useRevokeCaregiver();

  const [email, setEmail] = useState('');
  const [selected, setSelected] = useState<string[]>(['VIEW_ADHERENCE']);
  const [error, setError] = useState<string | null>(null);
  const [invitationToken, setInvitationToken] = useState<string | null>(null);

  function togglePermission(value: string) {
    setSelected((current) =>
      current.includes(value) ? current.filter((item) => item !== value) : [...current, value],
    );
  }

  async function sendInvitation() {
    if (email.trim().length === 0) {
      setError("Enter the caregiver's email address.");
      return;
    }

    setError(null);
    setInvitationToken(null);

    try {
      const result = await invite.mutateAsync({ email: email.trim(), permissions: selected });
      setEmail('');
      setInvitationToken(result.invitationToken);
    } catch (caught) {
      setError(describeError(caught));
    }
  }

  function confirmRevoke(id: string, label: string) {
    Alert.alert('Remove access?', `${label} will lose access immediately.`, [
      { text: 'Keep access', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: () => {
          void revoke.mutateAsync(id).catch((caught: unknown) => setError(describeError(caught)));
        },
      },
    ]);
  }

  return (
    <Screen style={{ paddingTop: insets.top }} refreshing={caregivers.isRefetching} onRefresh={() => void caregivers.refetch()}>
      <BackLink />

      <View className="gap-1">
        <Text variant="title">Caregivers</Text>
        <Text className="text-ink-muted">
          You stay the owner of your data. A caregiver only sees exactly what you approve, and you can remove access at
          any time.
        </Text>
      </View>

      <Card className="gap-4">
        <Text variant="heading">Invite a caregiver</Text>
        <TextField
          label="Email address"
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
          keyboardType="email-address"
          placeholder="caregiver@example.com"
        />

        <View className="gap-2">
          <Text variant="label">What they may see</Text>
          {caregiverPermissions.map((permission) => {
            const checked = selected.includes(permission.value);

            return (
              <Pressable
                key={permission.value}
                onPress={() => togglePermission(permission.value)}
                accessibilityRole="checkbox"
                accessibilityState={{ checked }}
                accessibilityLabel={permission.label}
                className="flex-row items-center gap-3 py-2"
              >
                <View
                  className={`h-6 w-6 items-center justify-center rounded-md border ${
                    checked ? 'border-brand-500 bg-brand-500' : 'border-line'
                  }`}
                >
                  {checked ? <Ionicons name="checkmark" size={16} color="#FFFFFF" /> : null}
                </View>
                <Text className="flex-1">{permission.label}</Text>
              </Pressable>
            );
          })}
        </View>

        <Button label="Send invitation" loading={invite.isPending} onPress={() => void sendInvitation()} />
      </Card>

      {invitationToken ? (
        <Callout
          tone="info"
          title="Invitation created"
          message={`Share this one-time code with the caregiver so they can accept: ${invitationToken}`}
        />
      ) : null}

      {error ? <Text className="text-sm text-critical-700">{error}</Text> : null}

      <View className="gap-3">
        <Text variant="heading">People with access</Text>

        {caregivers.isPending ? (
          <LoadingState />
        ) : caregivers.isError ? (
          <ErrorState message={describeError(caregivers.error)} onRetry={() => void caregivers.refetch()} />
        ) : (caregivers.data ?? []).length === 0 ? (
          <EmptyState
            icon="people-outline"
            title="Nobody has access"
            description="Invite someone you trust if you would like them to follow your medication routine."
          />
        ) : (
          (caregivers.data ?? []).map((caregiver) => (
            <Card key={caregiver.id} className="gap-3">
              <View className="flex-row items-start justify-between gap-3">
                <View className="flex-1 gap-1">
                  <Text variant="heading">{caregiver.displayName ?? caregiver.email}</Text>
                  <Text variant="caption">{caregiver.email}</Text>
                </View>
                <Badge
                  label={describeCaregiverStatus(caregiver.status)}
                  tone={caregiverStatusTone(caregiver.status)}
                  glyph={caregiverStatusGlyph(caregiver.status)}
                />
              </View>

              <Text variant="caption">
                Invited {formatDateTime(caregiver.createdAt)}
                {caregiver.acceptedAt ? ` · accepted ${formatDateTime(caregiver.acceptedAt)}` : ''}
              </Text>

              <View className="gap-2">
                {caregiverPermissions.map((permission) => {
                  const checked = caregiver.permissions.includes(permission.value);
                  const pending = !canApprovePermissions(caregiver.status);

                  return (
                    <Pressable
                      key={permission.value}
                      disabled={pending || updatePermissions.isPending}
                      onPress={() => {
                        const next = checked
                          ? caregiver.permissions.filter((item) => item !== permission.value)
                          : [...caregiver.permissions, permission.value];

                        void updatePermissions
                          .mutateAsync({ id: caregiver.id, permissions: next })
                          .catch((caught: unknown) => setError(describeError(caught)));
                      }}
                      accessibilityRole="checkbox"
                      accessibilityState={{ checked, disabled: pending }}
                      accessibilityLabel={permission.label}
                      className={`flex-row items-center gap-3 py-1.5 ${pending ? 'opacity-50' : ''}`}
                    >
                      <View
                        className={`h-5 w-5 items-center justify-center rounded border ${
                          checked ? 'border-brand-500 bg-brand-500' : 'border-line'
                        }`}
                      >
                        {checked ? <Ionicons name="checkmark" size={13} color="#FFFFFF" /> : null}
                      </View>
                      <Text className="flex-1 text-sm">{permission.label}</Text>
                    </Pressable>
                  );
                })}
              </View>

              {permissionHint(caregiver.status) ? (
                <Text variant="caption">{permissionHint(caregiver.status)}</Text>
              ) : null}

              <Button
                label="Remove access"
                variant="danger"
                size="md"
                icon={<Ionicons name="close-circle-outline" size={18} color={palette.critical} />}
                onPress={() => confirmRevoke(caregiver.id, caregiver.displayName ?? caregiver.email)}
              />
            </Card>
          ))
        )}
      </View>
    </Screen>
  );
}
