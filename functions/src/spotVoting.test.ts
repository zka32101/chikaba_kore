import { test } from 'node:test';
import assert from 'node:assert/strict';
import { decideSpotVoteEffect, SPOT_CONFIRM_APPROVE_THRESHOLD, SPOT_REPORT_HOLD_THRESHOLD } from './spotVoting';

test('decideSpotVoteEffect: confirmでvotesが増える', () => {
  const result = decideSpotVoteEffect({ votes: 0, reportCount: 0, status: 'pending' }, 'confirm');
  assert.equal(result.votes, 1);
  assert.equal(result.reportCount, 0);
});

test('decideSpotVoteEffect: confirmが閾値に達するとpendingからapprovedへ引き上がる', () => {
  const result = decideSpotVoteEffect(
    { votes: SPOT_CONFIRM_APPROVE_THRESHOLD - 1, reportCount: 0, status: 'pending' },
    'confirm'
  );
  assert.equal(result.status, 'approved');
});

test('decideSpotVoteEffect: confirmでもapproved済みのstatusは変わらない', () => {
  const result = decideSpotVoteEffect(
    { votes: SPOT_CONFIRM_APPROVE_THRESHOLD - 1, reportCount: 0, status: 'approved' },
    'confirm'
  );
  assert.equal(result.status, 'approved');
});

test('decideSpotVoteEffect: reportでreportCountが増える', () => {
  const result = decideSpotVoteEffect({ votes: 0, reportCount: 0, status: 'approved' }, 'report');
  assert.equal(result.reportCount, 1);
  assert.equal(result.votes, 0);
});

test('decideSpotVoteEffect: reportが閾値に達するとapprovedからpendingへ差し戻る', () => {
  const result = decideSpotVoteEffect(
    { votes: 0, reportCount: SPOT_REPORT_HOLD_THRESHOLD - 1, status: 'approved' },
    'report'
  );
  assert.equal(result.status, 'pending');
});

test('decideSpotVoteEffect: reportでもpending済みのstatusは変わらない', () => {
  const result = decideSpotVoteEffect(
    { votes: 0, reportCount: SPOT_REPORT_HOLD_THRESHOLD - 1, status: 'pending' },
    'report'
  );
  assert.equal(result.status, 'pending');
});
