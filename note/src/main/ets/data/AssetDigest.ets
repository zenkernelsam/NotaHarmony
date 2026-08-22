import { cryptoFramework } from '@kit.CryptoArchitectureKit';

export async function sha512Digest(data: Uint8Array): Promise<Uint8Array> {
  const digest = cryptoFramework.createMd('SHA512');
  await digest.update({ data: data });
  const result: cryptoFramework.DataBlob = await digest.digest();
  return result.data.slice();
}

export async function sha512Hex(data: Uint8Array): Promise<string> {
  const result: Uint8Array = await sha512Digest(data);
  let output: string = '';
  for (let index: number = 0; index < result.length; index++) {
    output += result[index].toString(16).padStart(2, '0');
  }
  return output;
}

export function originalAssetHashBitsFromSha512(bytes: Uint8Array): string[] {
  if (bytes.length !== 64) {
    throw new Error('original asset SHA-512 digest must contain 64 bytes');
  }
  const bits: string[] = [];
  for (let word: number = 0; word < 8; word++) {
    let decimal: string = '0';
    for (let byteIndex: number = 7; byteIndex >= 0; byteIndex--) {
      decimal = multiplyDecimalAndAdd(decimal, 256, bytes[word * 8 + byteIndex]);
    }
    bits.push(decimal);
  }
  return bits;
}

export function sha512BytesToHex(bytes: Uint8Array): string {
  if (bytes.length !== 64) {
    throw new Error('SHA-512 digest must contain 64 bytes');
  }
  let output: string = '';
  for (let index: number = 0; index < bytes.length; index++) {
    output += bytes[index].toString(16).padStart(2, '0');
  }
  return output;
}

function multiplyDecimalAndAdd(value: string, multiplier: number, addend: number): string {
  let carry: number = addend;
  let result: string = '';
  for (let index: number = value.length - 1; index >= 0; index--) {
    const next: number = (value.charCodeAt(index) - 0x30) * multiplier + carry;
    result = (next % 10).toString() + result;
    carry = Math.floor(next / 10);
  }
  while (carry > 0) {
    result = (carry % 10).toString() + result;
    carry = Math.floor(carry / 10);
  }
  let first: number = 0;
  while (first < result.length - 1 && result.charAt(first) === '0') {
    first++;
  }
  return result.substring(first);
}
