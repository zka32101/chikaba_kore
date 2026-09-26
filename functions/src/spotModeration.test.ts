import { test } from 'node:test';
import assert from 'node:assert/strict';
import { decideInitialStatus, containsNgWord, decideCommentModerationStatus } from './spotModeration';

test('decideInitialStatus: autoApproveAnonymousがtrueなら承認', () => {
  assert.equal(decideInitialStatus({ autoApproveAnonymous: true }), 'approved');
});

test('decideInitialStatus: autoApproveAnonymousがfalseなら保留', () => {
  assert.equal(decideInitialStatus({ autoApproveAnonymous: false }), 'pending');
});

test('decideInitialStatus: requiresManualReviewがtrueなら地域設定に関わらず保留', () => {
  assert.equal(
    decideInitialStatus({ autoApproveAnonymous: true }, { requiresManualReview: true }),
    'pending'
  );
});

test('containsNgWord: NGワードを含む場合はtrue', () => {
  assert.equal(containsNgWord('死ねって言われた'), true);
});

test('containsNgWord: 区切り文字を挟んだ回避を検知する', () => {
  assert.equal(containsNgWord('死　ね'), true);
  assert.equal(containsNgWord('死・ね'), true);
  assert.equal(containsNgWord('死-ね'), true);
});

test('containsNgWord: NGワードを含まない場合はfalse', () => {
  assert.equal(containsNgWord('今日はいい天気です'), false);
});

test('containsNgWord: 空文字・undefinedはfalse', () => {
  assert.equal(containsNgWord(''), false);
  assert.equal(containsNgWord(undefined), false);
});

test('decideCommentModerationStatus: NGワードを含むと拒否', () => {
  assert.equal(decideCommentModerationStatus('クズ'), 'rejected');
});

test('decideCommentModerationStatus: NGワードを含まないと承認', () => {
  assert.equal(decideCommentModerationStatus('いい道でした'), 'approved');
});
