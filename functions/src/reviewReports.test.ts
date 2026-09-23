import { test } from 'node:test';
import assert from 'node:assert/strict';
import { exceedsReportThreshold, REPORT_THRESHOLD } from './reviewReports';

test('exceedsReportThreshold: しきい値以下なら超過しない', () => {
  assert.equal(exceedsReportThreshold(0), false);
  assert.equal(exceedsReportThreshold(1), false);
  assert.equal(exceedsReportThreshold(REPORT_THRESHOLD), false);
});

test('exceedsReportThreshold: しきい値を超えたら超過と判定する', () => {
  assert.equal(exceedsReportThreshold(REPORT_THRESHOLD + 1), true);
  assert.equal(exceedsReportThreshold(REPORT_THRESHOLD + 100), true);
});
