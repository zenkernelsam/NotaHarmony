import { cryptoFramework } from '@kit.CryptoArchitectureKit';

export async function sha256Hex(data: Uint8Array): Promise<string> {
  const digest = cryptoFramework.createMd('SHA256');
  await digest.update({ data: data });
  const result: cryptoFramework.DataBlob = await digest.digest();
  let output: string = '';
  for (let i: number = 0; i < result.data.length; i++) {
    output += result.data[i].toString(16).padStart(2, '0');
  }
  return output;
}
