import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  exceedsSpotRateLimit,
  SPOT_RATE_LIMIT_MAX_SUBMISSIONS,
  decideRateLimitTransition,
} from './spotRateLimiting';

test('exceedsSpotRateLimit: 上限件数以下なら超過しない', () => {
  assert.equal(exceedsSpotRateLimit(0), false);
  assert.equal(exceedsSpotRateLimit(SPOT_RATE_LIMIT_MAX_SUBMISSIONS), false);
});

test('exceedsSpotRateLimit: 上限件数を超えたら超過と判定する', () => {
  assert.equal(exceedsSpotRateLimit(SPOT_RATE_LIMIT_MAX_SUBMISSIONS + 1), true);
});

test('decideRateLimitTransition: 初回呼び出しは許可される', () => {
  const result = decideRateLimitTransition(null, 1000, 60_000, 5);
  assert.equal(result.allow, true);
  assert.deepEqual(result.nextState, { windowStartMs: 1000, count: 1 });
});

test('decideRateLimitTransition: ウィンドウ内で上限未満なら許可されカウントが増える', () => {
  const result = decideRateLimitTransition({ windowStartMs: 1000, count: 2 }, 1500, 60_000, 5);
  assert.equal(result.allow, true);
  assert.deepEqual(result.nextState, { windowStartMs: 1000, count: 3 });
});

test('decideRateLimitTransition: ウィンドウ内で上限に達したら拒否されカウントは進まない', () => {
  const existing = { windowStartMs: 1000, count: 5 };
  const result = decideRateLimitTransition(existing, 1500, 60_000, 5);
  assert.equal(result.allow, false);
  assert.deepEqual(result.nextState, existing);
});

test('decideRateLimitTransition: ウィンドウ経過後は新しいウィンドウとして許可される', () => {
  const result = decideRateLimitTransition({ windowStartMs: 1000, count: 5 }, 70_000, 60_000, 5);
  assert.equal(result.allow, true);
  assert.deepEqual(result.nextState, { windowStartMs: 70_000, count: 1 });
});
