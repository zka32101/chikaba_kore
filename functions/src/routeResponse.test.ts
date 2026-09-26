import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildGraph } from './routeGraph';
import { buildSegmentBreakdown } from './routeResponse';

test('buildSegmentBreakdown: パスをfrom/toの区間内訳に変換する', () => {
  const graph = buildGraph({
    nodes: [
      { id: 'n1', lat: 35.0, lon: 139.0 },
      { id: 'n2', lat: 35.001, lon: 139.0 },
      { id: 'n3', lat: 35.002, lon: 139.0 },
    ],
    roads: [{ id: 'r1', nodeIds: ['n1', 'n2', 'n3'] }],
  });
  graph.edges[0].shadowScore = 1;

  const segments = buildSegmentBreakdown(graph, ['n1', 'n2', 'n3']);
  assert.equal(segments.length, 2);
  assert.equal(segments[0].fromLat, 35.0);
  assert.equal(segments[0].toLat, 35.001);
  assert.equal(segments[0].comfortScore, 1);
  assert.equal(segments[1].comfortScore, 0);
});
