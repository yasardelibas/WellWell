import { useCssElement, type StyledConfiguration, type StyledProps } from 'react-native-css';
import { SafeAreaView as OriginalSafeAreaView, type SafeAreaViewProps } from 'react-native-safe-area-context';

const mapping = {
  className: 'style',
} satisfies StyledConfiguration<typeof OriginalSafeAreaView>;

/**
 * `react-native-safe-area-context` sits outside the NativeWind babel rewrite, so it needs an
 * explicit interop to understand `className`.
 */
export function SafeAreaView(props: StyledProps<SafeAreaViewProps, typeof mapping>) {
  return useCssElement(OriginalSafeAreaView, props, mapping);
}
