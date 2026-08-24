import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const sortStart = page.indexOf('  private setSortMode(mode: NoteSortMode): void {');
const themeStart = page.indexOf('  private setThemeMode(mode: ThemeMode): void {');
assert.ok(sortStart !== -1 && themeStart > sortStart);

const themeEnd = page.indexOf('  // 原版 folder row 约 48dp：左侧 chevron 负责展开/折叠，中间整行选择，右侧保留操作菜单。',
  themeStart);
assert.ok(themeEnd > themeStart);
const theme = page.slice(themeStart, themeEnd);
const guard = 'if (!this.pageActive) {\n      return;\n    }';
const guardIndex = theme.indexOf(guard);
assert.ok(guardIndex >= 0);
assert.ok(theme.indexOf(guard) === 0 || theme.slice(0, guardIndex) === '  private setThemeMode(mode: ThemeMode): void {\n    ', 'the guard must be the first executable statement');

for (const effect of [
  'ThemeStore.setMode(mode);',
  'this.refreshThumbnails().catch',
  'preferences.getPreferences(context, THEME_PREFERENCES_NAME)',
  'pref.putSync(THEME_PREFERENCE_KEY, mode);',
]) {
  const effectIndex = theme.indexOf(effect);
  assert.ok(effectIndex > guardIndex, effect);
}

const menuActions = [...page.matchAll(/action: \(\) => \{ this\.setThemeMode\(.*?\); \} \}/g)];
assert.ok(menuActions.length >= 6, 'both compact and full theme menus remain wired');

console.log('D02_LIBRARY_THEME_MODE_LIFECYCLE_BOUND_REPLAY_OK TOTAL=7 FAILED=0');
