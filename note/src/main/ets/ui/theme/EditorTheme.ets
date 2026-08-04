// T-038 主题 token（Light/Dark 色板 + 解析）
// 纯类型 + 常量：不 import 平台模块

export interface ThemeTokens {
  background: string;      // 页面背景
  surface: string;         // 卡片/工具栏背景
  textPrimary: string;
  textSecondary: string;
  paperBackground: string; // 画布纸张底色
  paperLineColor: string;  // 纸张线/点颜色
  accent: string;          // 选中高亮
}

export const LightTheme: ThemeTokens = {
  background: '#F5F5F5',
  surface: '#FFFFFF',
  textPrimary: '#000000',
  textSecondary: '#888888',
  paperBackground: '#FFFFFF',
  paperLineColor: '#E0E0E0',
  accent: '#3366FF',
};

export const DarkTheme: ThemeTokens = {
  background: '#1A1A1A',
  surface: '#262626',
  textPrimary: '#E6E6E6',
  textSecondary: '#999999',
  paperBackground: '#262626',
  paperLineColor: '#3A3A3A',
  accent: '#5B8CFF',
};

// 主题模式
export type ThemeMode = 'system' | 'light' | 'dark';
