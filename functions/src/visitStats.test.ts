import { test } from 'node:test';
import assert from 'node:assert/strict';
import { shouldIncrementVisitOnFavoriteWrite } from './visitStats';

test('shouldIncrementVisitOnFavoriteWrite: want_to_goからwill_goへの変化はカウント対象', () => {
  assert.equal(shouldIncrementVisitOnFavoriteWrite('want_to_go', 'will_go'), true);
  assert.equal(shouldIncrementVisitOnFavoriteWrite(undefined, 'will_go'), true);
});

test('shouldIncrementVisitOnFavoriteWrite: will_go以外への変化・will_goのまま更新はカウント対象外', () => {
  assert.equal(shouldIncrementVisitOnFavoriteWrite('want_to_go', 'want_to_go'), false);
  assert.equal(shouldIncrementVisitOnFavoriteWrite('will_go', 'will_go'), false);
  assert.equal(shouldIncrementVisitOnFavoriteWrite('will_go', 'want_to_go'), false);
  assert.equal(shouldIncrementVisitOnFavoriteWrite('will_go', undefined), false);
});
