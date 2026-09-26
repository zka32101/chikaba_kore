import { test } from 'node:test';
import assert from 'node:assert/strict';
import { haversineDistanceM, midpoint, toRad, toDeg } from './routeGeo';

test('toRad/toDeg: 相互変換で元に戻る', () => {
  assert.ok(Math.abs(toDeg(toRad(45)) - 45) < 1e-9);
});

test('haversineDistanceM: 同一点の距離は0', () => {
  assert.equal(haversineDistanceM([35.681, 139.767], [35.681, 139.767]), 0);
});

test('haversineDistanceM: 東京駅〜新宿駅の距離は概ね6-7km', () => {
  const distanceM = haversineDistanceM([35.681236, 139.767125], [35.690921, 139.700258]);
  assert.ok(distanceM > 5000 && distanceM < 8000, `distanceM=${distanceM}`);
});

test('midpoint: 単純な中点を計算する', () => {
  const mid = midpoint([0, 0], [2, 4]);
  assert.deepEqual(mid, [1, 2]);
});
