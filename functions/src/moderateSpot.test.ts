import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spotCollectionName } from './moderateSpot';

test('spotCollectionName: shadeはshadeSpotsを返す', () => {
  assert.equal(spotCollectionName('shade'), 'shadeSpots');
});

test('spotCollectionName: brightnessはbrightnessSpotsを返す', () => {
  assert.equal(spotCollectionName('brightness'), 'brightnessSpots');
});
