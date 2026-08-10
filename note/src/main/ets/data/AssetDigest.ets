import { cryptoFramework } from '@kit.CryptoArchitectureKit';

export async function sha512Hex(data: Uint8Array): Promise<string> {
  const digest = cryptoFramework.createMd('SHA512');
  await digest.update({ data: data });
  const result: cryptoFramework.DataBlob = await digest.digest();
  let output: string = '';
  for (let index: number = 0; index < result.data.length; index++) {
    output += result.data[index].toString(16).padStart(2, '0');
  }
  return output;
}
