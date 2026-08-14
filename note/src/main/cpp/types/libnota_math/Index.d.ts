export interface MathMeasureResult {
  valid: boolean;
  width?: number;
  height?: number;
  baseline?: number;
  depth?: number;
  error?: string;
}

export interface MathRenderResult {
  valid: boolean;
  width?: number;
  height?: number;
  pixels?: ArrayBuffer;
  error?: string;
}

export const initialize: (resourceRoot: string) => boolean;
export const measure: (latex: string, width: number, fontSize: number) => MathMeasureResult;
export const render: (latex: string, width: number, height: number,
  fontSize: number, argbColor: number, pixelScale: number) => MathRenderResult;
