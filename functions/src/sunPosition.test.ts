import { test } from 'node:test';
import assert from 'node:assert/strict';
import { getSunPosition } from './sunPosition';

const TOKYO_LAT = 35.681236;
const TOKYO_LON = 139.767125;

test('getSunPosition: 東京の現地時間正午（夏）は太陽高度が正', () => {
  // JST(UTC+9)の正午 = UTC 3:00
  const pos = getSunPosition(new Date('2026-06-21T03:00:00Z'), TOKYO_LAT, TOKYO_LON);
  assert.ok(pos.altitudeDeg > 0, `altitudeDeg=${pos.altitudeDeg}`);
});

test('getSunPosition: 東京の現地時間深夜は太陽高度が負', () => {
  // JST(UTC+9)の深夜0時 = UTC 15:00（前日）
  const pos = getSunPosition(new Date('2026-06-21T15:00:00Z'), TOKYO_LAT, TOKYO_LON);
  assert.ok(pos.altitudeDeg < 0, `altitudeDeg=${pos.altitudeDeg}`);
});
