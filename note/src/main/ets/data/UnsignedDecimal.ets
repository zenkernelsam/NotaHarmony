export const MAX_UNSIGNED_LONG_DECIMAL: string = '18446744073709551615';

export function validateUnsignedLongDecimal(value: string): void {
  if (value.length === 0 || value.length > MAX_UNSIGNED_LONG_DECIMAL.length ||
    (value.length > 1 && value.charAt(0) === '0')) {
    throw new Error('unsigned 64-bit decimal is not canonical');
  }
  for (let index: number = 0; index < value.length; index++) {
    const code: number = value.charCodeAt(index);
    if (code < 0x30 || code > 0x39) {
      throw new Error('unsigned 64-bit decimal contains a non-digit');
    }
  }
  if (value.length === MAX_UNSIGNED_LONG_DECIMAL.length && value > MAX_UNSIGNED_LONG_DECIMAL) {
    throw new Error('unsigned 64-bit decimal is exhausted');
  }
}

export function compareUnsignedLongDecimal(left: string, right: string): number {
  validateUnsignedLongDecimal(left);
  validateUnsignedLongDecimal(right);
  if (left.length !== right.length) {
    return left.length < right.length ? -1 : 1;
  }
  if (left === right) {
    return 0;
  }
  return left < right ? -1 : 1;
}

export function maxUnsignedLongDecimal(left: string | null, right: string): string {
  validateUnsignedLongDecimal(right);
  if (left === null) {
    return right;
  }
  return compareUnsignedLongDecimal(left, right) >= 0 ? left : right;
}
