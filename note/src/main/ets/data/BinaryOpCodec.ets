import { util } from '@kit.ArkTS';

export const MAX_OPERATION_ELEMENTS: number = 100000;
export const MAX_OPERATION_STRING_BYTES: number = 1024 * 1024;
export const MAX_OPERATION_BYTES: number = 64 * 1024 * 1024;

export function encodeOperationString(value: string, label: string): Uint8Array {
  const bytes: Uint8Array = new util.TextEncoder().encodeInto(value);
  if (bytes.length > MAX_OPERATION_STRING_BYTES) {
    throw new Error(`${label} is too large`);
  }
  return bytes;
}

export class BinaryOpWriter {
  private output: Uint8Array;
  private offset: number = 0;

  constructor(output: Uint8Array) {
    if (output.length > MAX_OPERATION_BYTES) {
      throw new Error('operation writer exceeds byte budget');
    }
    this.output = output;
  }

  writeByte(value: number): void {
    if (this.offset >= this.output.length) {
      throw new Error('operation writer overflow');
    }
    this.output[this.offset++] = value & 0xFF;
  }

  writeUint32(value: number): void {
    if (!Number.isSafeInteger(value) || value < 0 || value > 0xFFFFFFFF) {
      throw new Error('uint32 value is out of range');
    }
    this.writeByte(value);
    this.writeByte(value / 0x100);
    this.writeByte(value / 0x10000);
    this.writeByte(value / 0x1000000);
  }

  writeSafeInteger(value: number): void {
    if (!Number.isSafeInteger(value) || value < 0) {
      throw new Error('safe integer value is out of range');
    }
    const low: number = value % 0x100000000;
    const high: number = Math.floor(value / 0x100000000);
    this.writeUint32(low);
    this.writeUint32(high);
  }

  writeSizedBytes(value: Uint8Array): void {
    this.writeUint32(value.length);
    this.writeBytes(value);
  }

  writeBytes(value: Uint8Array): void {
    if (this.offset + value.length > this.output.length) {
      throw new Error('operation writer overflow');
    }
    this.output.set(value, this.offset);
    this.offset += value.length;
  }

  finish(): Uint8Array {
    if (this.offset !== this.output.length) {
      throw new Error('operation writer size mismatch');
    }
    return this.output;
  }
}

export class BinaryOpReader {
  private input: Uint8Array;
  private offset: number = 0;

  constructor(input: Uint8Array) {
    if (input.length > MAX_OPERATION_BYTES) {
      throw new Error('operation exceeds byte budget');
    }
    this.input = input;
  }

  readByte(): number {
    this.require(1);
    return this.input[this.offset++];
  }

  readMagic(expected: number[]): void {
    for (const value of expected) {
      if (this.readByte() !== value) {
        throw new Error('invalid operation magic');
      }
    }
  }

  readUint32(): number {
    this.require(4);
    const value: number = this.input[this.offset] + this.input[this.offset + 1] * 0x100 +
      this.input[this.offset + 2] * 0x10000 + this.input[this.offset + 3] * 0x1000000;
    this.offset += 4;
    return value;
  }

  readSafeInteger(): number {
    const low: number = this.readUint32();
    const high: number = this.readUint32();
    const value: number = low + high * 0x100000000;
    if (!Number.isSafeInteger(value)) {
      throw new Error('integer exceeds JavaScript safe range');
    }
    return value;
  }

  readSizedBytes(maxLength: number): Uint8Array {
    const length: number = this.readUint32();
    if (length > maxLength) {
      throw new Error('length exceeds operation budget');
    }
    this.require(length);
    const value: Uint8Array = this.input.slice(this.offset, this.offset + length);
    this.offset += length;
    return value;
  }

  readString(): string {
    const bytes: Uint8Array = this.readSizedBytes(MAX_OPERATION_STRING_BYTES);
    const decoder = util.TextDecoder.create('utf-8');
    const value: string = decoder.decodeToString(bytes);
    if (!sameBytes(bytes, new util.TextEncoder().encodeInto(value))) {
      throw new Error('invalid UTF-8 in operation');
    }
    return value;
  }

  atEnd(): boolean {
    return this.offset === this.input.length;
  }

  private require(length: number): void {
    if (length < 0 || this.offset + length > this.input.length) {
      throw new Error('truncated operation');
    }
  }
}

export function sameBytes(left: Uint8Array, right: Uint8Array): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let i: number = 0; i < left.length; i++) {
    if (left[i] !== right[i]) {
      return false;
    }
  }
  return true;
}
