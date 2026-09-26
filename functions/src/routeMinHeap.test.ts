import { test } from 'node:test';
import assert from 'node:assert/strict';
import { MinHeap } from './routeMinHeap';

test('MinHeap: 優先度の小さい順に取り出せる', () => {
  const heap = new MinHeap<string>();
  heap.push('c', 3);
  heap.push('a', 1);
  heap.push('b', 2);
  assert.equal(heap.pop()?.item, 'a');
  assert.equal(heap.pop()?.item, 'b');
  assert.equal(heap.pop()?.item, 'c');
  assert.ok(heap.isEmpty());
});

test('MinHeap: 空のときisEmptyがtrue', () => {
  const heap = new MinHeap<string>();
  assert.ok(heap.isEmpty());
  assert.equal(heap.pop(), undefined);
});
