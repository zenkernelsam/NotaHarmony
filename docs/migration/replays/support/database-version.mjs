import assert from 'node:assert/strict';

export function readDatabaseVersion(source) {
  assert.equal(typeof source, 'string', 'database helper source must be text');
  const matches = [...source.matchAll(
    /^export const DB_VERSION:\s*number\s*=\s*(\d+);\s*$/gm)];
  assert.equal(matches.length, 1, 'database helper must export exactly one integer DB_VERSION');
  const version = Number(matches[0][1]);
  assert.ok(Number.isSafeInteger(version) && version >= 1,
    `database helper has invalid DB_VERSION: ${matches[0][1]}`);
  return version;
}

export function assertDatabaseVersionAtLeast(source, minimum) {
  assert.ok(Number.isSafeInteger(minimum) && minimum >= 1,
    `minimum database version is invalid: ${minimum}`);
  const actual = readDatabaseVersion(source);
  assert.ok(actual >= minimum,
    `database version ${actual} is below required version ${minimum}`);
  return actual;
}
