import assert from 'node:assert/strict';
import {
  assertDatabaseVersionAtLeast, readDatabaseVersion,
} from './support/database-version.mjs';

const source = (version) => `export const DB_VERSION: number = ${version};`;

assert.equal(readDatabaseVersion(source(62)), 62);
assert.equal(assertDatabaseVersionAtLeast(source(61), 61), 61);
assert.equal(assertDatabaseVersionAtLeast(source(62), 61), 62);
assert.equal(assertDatabaseVersionAtLeast(source(100), 61), 100);
assert.throws(() => assertDatabaseVersionAtLeast(source(60), 61), /below required version/);
assert.throws(() => readDatabaseVersion('export const DB_VERSION: number = 62.5;'),
  /must export exactly one integer DB_VERSION/);
assert.throws(() => readDatabaseVersion('const DB_VERSION = 62;'),
  /must export exactly one integer DB_VERSION/);
assert.throws(() => readDatabaseVersion('// export const DB_VERSION: number = 62;'),
  /must export exactly one integer DB_VERSION/);
assert.throws(() => readDatabaseVersion(`${source(61)}\n${source(62)}`),
  /must export exactly one integer DB_VERSION/);
assert.throws(() => assertDatabaseVersionAtLeast(source(62), 0),
  /minimum database version is invalid/);

console.log('TOTAL=10 FAILED=0');
