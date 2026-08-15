import { ImageManipulator, SaveFormat } from 'expo-image-manipulator';

/** Width that keeps label text legible while staying well inside the upload limit. */
const TARGET_WIDTH = 1400;

export interface PreparedImage {
  base64: string;
  mimeType: string;
}

/**
 * Downscales and re-encodes the capture before it leaves the device. The original file is
 * never uploaded and never stored by the app.
 */
export async function prepareLabelImage(uri: string): Promise<PreparedImage> {
  const context = ImageManipulator.manipulate(uri).resize({ width: TARGET_WIDTH, height: null });
  const rendered = await context.renderAsync();
  const saved = await rendered.saveAsync({ format: SaveFormat.JPEG, compress: 0.6, base64: true });

  if (!saved.base64) {
    throw new Error('The captured image could not be prepared.');
  }

  return { base64: saved.base64, mimeType: 'image/jpeg' };
}
