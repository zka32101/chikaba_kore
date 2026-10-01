import { test } from 'node:test';
import assert from 'node:assert/strict';
import { isValidCongestionLevel } from './submitCongestionReport';

test('isValidCongestionLevel: empty/normal/crowdedはtrue', () => {
  assert.equal(isValidCongestionLevel('empty'), true);
  assert.equal(isValidCongestionLevel('normal'), true);
  assert.equal(isValidCongestionLevel('crowded'), true);
});

test('isValidCongestionLevel: 未知の値や非文字列はfalse', () => {
  assert.equal(isValidCongestionLevel('busy'), false);
  assert.equal(isValidCongestionLevel(undefined), false);
  assert.equal(isValidCongestionLevel(123), false);
});
