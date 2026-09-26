import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildSpatialIndex, nearestNodeIdIndexed, itemsWithinBoundingBoxIndexed } from './routeSpatialIndex';

const nodes = [
  { id: 'a', lat: 35.0, lon: 139.0 },
  { id: 'b', lat: 35.01, lon: 139.01 },
  { id: 'c', lat: 35.5, lon: 139.5 },
];

test('nearestNodeIdIndexed: 最も近いノードを返す', () => {
  const index = buildSpatialIndex(nodes);
  assert.equal(nearestNodeIdIndexed(index, 35.001, 139.001), 'a');
  assert.equal(nearestNodeIdIndexed(index, 35.009, 139.009), 'b');
});

test('nearestNodeIdIndexed: 空のインデックスではnull', () => {
  const index = buildSpatialIndex([]);
  assert.equal(nearestNodeIdIndexed(index, 35.0, 139.0), null);
});

test('itemsWithinBoundingBoxIndexed: 範囲内のノードのみ返す', () => {
  const index = buildSpatialIndex(nodes);
  const results = itemsWithinBoundingBoxIndexed(index, 35.0, 139.0, 0.02);
  const ids = results.map((n) => n.id).sort();
  assert.deepEqual(ids, ['a', 'b']);
});
