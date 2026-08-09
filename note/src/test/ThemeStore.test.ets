import { describe, it, expect } from '@ohos/hypium';
import { ThemeStore } from '../main/ets/ui/theme/ThemeStore';

export default function themeStoreTest() {
  describe('ThemeStore', () => {
    it('normalizes persisted theme modes before applying them', 0, () => {
      expect(ThemeStore.normalizeMode('system')).assertEqual('system');
      expect(ThemeStore.normalizeMode('light')).assertEqual('light');
      expect(ThemeStore.normalizeMode('dark')).assertEqual('dark');
      expect(ThemeStore.normalizeMode('unknown')).assertEqual('system');
      expect(ThemeStore.normalizeMode('')).assertEqual('system');
    });
  });
}
