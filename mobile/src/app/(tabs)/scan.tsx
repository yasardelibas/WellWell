import { Ionicons } from '@expo/vector-icons';
import { CameraView, useCameraPermissions } from 'expo-camera';
import * as Haptics from 'expo-haptics';
import * as ImagePicker from 'expo-image-picker';
import { useFocusEffect, useRouter } from 'expo-router';
import { useCallback, useRef, useState } from 'react';
import { ActivityIndicator, Pressable, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { SafeAreaView } from '@/components/ui/SafeAreaView';
import { Text } from '@/components/ui/Text';
import { prepareLabelImage } from '@/features/scanner/image';
import { useScanStore } from '@/features/scanner/store';
import { describeError } from '@/services/api/client';
import { scanApi } from '@/services/api/endpoints';
import { palette } from '@/theme/tokens';

export default function ScanScreen() {
  const router = useRouter();
  const cameraRef = useRef<CameraView>(null);
  const [permission, requestPermission] = useCameraPermissions();
  const [torch, setTorch] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [cameraReady, setCameraReady] = useState(false);
  const [active, setActive] = useState(false);
  const setScan = useScanStore((state) => state.setScan);

  // Only one camera preview may be live at a time, so it is torn down when unfocused.
  useFocusEffect(
    useCallback(() => {
      setActive(true);

      return () => {
        setActive(false);
        setTorch(false);
      };
    }, []),
  );

  async function submit(image: { base64: string; mimeType: string }) {
    setBusy(true);
    setError(null);

    try {
      const result = await scanApi.submit({ imageBase64: image.base64, mimeType: image.mimeType });
      setScan(result);
      router.push('/scan/review');
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  }

  async function capture() {
    if (!cameraRef.current || busy || !cameraReady) {
      return;
    }

    setBusy(true);
    setError(null);

    try {
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      const photo = await cameraRef.current.takePictureAsync({ quality: 0.8, skipProcessing: false });

      if (!photo?.uri) {
        throw new Error('capture-failed');
      }

      const prepared = await prepareLabelImage(photo.uri);
      await submit(prepared);
    } catch (caught) {
      setError(
        caught instanceof Error && caught.message === 'capture-failed'
          ? "We couldn't capture the label. Please try again."
          : describeError(caught),
      );
      setBusy(false);
    }
  }

  async function pickFromLibrary() {
    setError(null);

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.8,
      allowsEditing: false,
    });

    const asset = result.assets?.[0];
    if (result.canceled || !asset) {
      return;
    }

    try {
      setBusy(true);
      const prepared = await prepareLabelImage(asset.uri);
      await submit(prepared);
    } catch (caught) {
      setError(describeError(caught));
      setBusy(false);
    }
  }

  if (!permission) {
    return (
      <SafeAreaView className="flex-1 items-center justify-center bg-canvas">
        <ActivityIndicator color={palette.brand} />
      </SafeAreaView>
    );
  }

  if (!permission.granted) {
    return (
      <SafeAreaView className="flex-1 bg-canvas">
        <View className="flex-1 justify-center gap-4 px-6">
          <Ionicons name="camera-outline" size={32} color={palette.brand} />
          <Text variant="title">Camera access is needed to read labels</Text>
          <Text className="text-ink-muted">
            MedGuard reads the medication name and ingredients from the label. The photo is processed to extract text
            and is not stored.
          </Text>
          <Button label="Allow camera access" onPress={() => void requestPermission()} />
          <Button label="Enter label text instead" variant="secondary" onPress={() => router.push('/scan/manual')} />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <View className="flex-1 bg-ink">
      {active ? (
        <CameraView
          ref={cameraRef}
          style={{ flex: 1 }}
          facing="back"
          enableTorch={torch}
          onCameraReady={() => setCameraReady(true)}
        />
      ) : (
        <View className="flex-1" />
      )}

      <SafeAreaView className="absolute inset-0 justify-between">
        <View className="gap-3 px-5 pt-2">
          <Text className="text-center text-lg font-semibold text-white">Scan medication label</Text>
          <Text className="text-center text-sm text-white/80">
            Place the medication name and ingredients inside the frame.
          </Text>
        </View>

        <View className="items-center px-6">
          <View
            className="h-56 w-full rounded-3xl border-2 border-white/70"
            accessibilityLabel="Scan frame. Align the label inside this area."
          />
          {busy ? (
            <View className="mt-4 flex-row items-center gap-2 rounded-full bg-black/60 px-4 py-2">
              <ActivityIndicator size="small" color="#FFFFFF" />
              <Text className="text-sm text-white">Reading the label…</Text>
            </View>
          ) : null}
          {error ? (
            <View className="mt-4 rounded-2xl bg-black/70 px-4 py-3">
              <Text className="text-center text-sm text-white">{error}</Text>
            </View>
          ) : null}
        </View>

        <View className="gap-4 px-6 pb-4">
          <View className="flex-row items-center justify-between">
            <CircleButton
              icon="images-outline"
              label="Choose a photo from your library"
              onPress={() => void pickFromLibrary()}
              disabled={busy}
            />

            <Pressable
              onPress={() => void capture()}
              disabled={busy || !cameraReady}
              accessibilityRole="button"
              accessibilityLabel="Capture the medication label"
              className={`h-20 w-20 items-center justify-center rounded-full border-4 border-white ${
                busy ? 'bg-white/40' : 'bg-white/90 active:bg-white'
              }`}
            >
              <Ionicons name="camera" size={30} color={palette.ink} />
            </Pressable>

            <CircleButton
              icon={torch ? 'flashlight' : 'flashlight-outline'}
              label={torch ? 'Turn the flashlight off' : 'Turn the flashlight on'}
              onPress={() => setTorch((value) => !value)}
              disabled={busy}
            />
          </View>

          <Pressable
            onPress={() => router.push('/scan/manual')}
            accessibilityRole="button"
            accessibilityLabel="Type the label text instead"
            className="items-center py-2"
          >
            <Text className="font-semibold text-white">Type the label text instead</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    </View>
  );
}

function CircleButton({
  icon,
  label,
  onPress,
  disabled,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  onPress: () => void;
  disabled?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      accessibilityRole="button"
      accessibilityLabel={label}
      className={`h-14 w-14 items-center justify-center rounded-full bg-white/20 active:bg-white/30 ${
        disabled ? 'opacity-50' : ''
      }`}
    >
      <Ionicons name={icon} size={22} color="#FFFFFF" />
    </Pressable>
  );
}
