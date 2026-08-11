export type CaptureEventCallback = (kind: number, code: number) => void;

export const setEventCallback: (callback: CaptureEventCallback | null) => void;
export const isCaptureActive: () => boolean;
export const startCapture: (outputUrl: string) => number;
export const stopCapture: () => number;
export const abortCapture: () => void;
