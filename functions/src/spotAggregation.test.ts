import { test } from 'node:test';
import assert from 'node:assert/strict';
import { computeWeightedAverage, computeTrustWeight } from './spotAggregation';

test('computeWeightedAverage: サンプル数0件目は新規値で完全に置き換わる', () => {
  const result = computeWeightedAverage(0.2, 1.0, 0);
  assert.equal(result, 1.0); // baseWeight = 1/(0+1) = 1
});

test('computeWeightedAverage: サンプル数1件目は現在値と新規値の単純平均になる', () => {
  const result = computeWeightedAverage(0.2, 1.0, 1);
  assert.equal(result, 0.6); // (0.2*0.5 + 1.0*0.5)
});

test('computeWeightedAverage: サンプル数が増えるほど新規値の影響が小さくなる', () => {
  const early = computeWeightedAverage(0.5, 1.0, 0);
  const later = computeWeightedAverage(0.5, 1.0, 10);
  assert.ok(later - 0.5 < early - 0.5);
});

test('computeWeightedAverage: 結果は0〜1にクランプされる', () => {
  assert.ok(computeWeightedAverage(1, 1, 0) <= 1);
  assert.ok(computeWeightedAverage(0, 0, 0) >= 0);
});

test('computeTrustWeight: 本人確認済みは重みが大きい', () => {
  const verified = computeTrustWeight({ isVerified: true });
  const anonymous = computeTrustWeight({ isVerified: false });
  const noProfile = computeTrustWeight(undefined);
  assert.ok(verified > 1);
  assert.ok(anonymous < 1);
  assert.equal(anonymous, noProfile);
});
