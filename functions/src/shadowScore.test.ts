import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildGraph } from './routeGraph';
import { computeShadowScores } from './shadowScore';

function buildSimpleGraph() {
  return buildGraph({
    nodes: [
      { id: 'n1', lat: 35.0, lon: 139.0 },
      { id: 'n2', lat: 35.0002, lon: 139.0 },
    ],
    roads: [{ id: 'r1', nodeIds: ['n1', 'n2'] }],
  });
}

test('computeShadowScores: 建物が無い場合は全辺0', () => {
  const graph = buildSimpleGraph();
  const scores = computeShadowScores(graph, [], new Date('2026-06-21T03:00:00Z'));
  for (const edge of graph.edges) {
    assert.equal(scores.get(edge.id), 0);
  }
});

test('computeShadowScores: 日没後（深夜）は全辺0', () => {
  const graph = buildSimpleGraph();
  const buildings = [{ id: 'b1', heightM: 30, center: [35.0001, 139.0] as [number, number] }];
  const scores = computeShadowScores(graph, buildings, new Date('2026-06-21T15:00:00Z'));
  for (const edge of graph.edges) {
    assert.equal(scores.get(edge.id), 0);
  }
});
