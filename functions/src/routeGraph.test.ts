import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildGraph } from './routeGraph';

test('buildGraph: 道路のノード列から両方向の辺を構築する', () => {
  const graph = buildGraph({
    nodes: [
      { id: 'n1', lat: 35.0, lon: 139.0 },
      { id: 'n2', lat: 35.001, lon: 139.0 },
      { id: 'n3', lat: 35.002, lon: 139.0 },
    ],
    roads: [{ id: 'r1', nodeIds: ['n1', 'n2', 'n3'] }],
  });

  assert.equal(graph.edges.length, 2);
  assert.equal(graph.adjacency.get('n1')?.length, 1);
  assert.equal(graph.adjacency.get('n2')?.length, 2); // n1とn3の両方に隣接
  assert.equal(graph.adjacency.get('n1')?.[0].to, 'n2');
  assert.ok((graph.edges[0].distanceM ?? 0) > 0);
});

test('buildGraph: 存在しないノードidを参照する道路は無視する', () => {
  const graph = buildGraph({
    nodes: [{ id: 'n1', lat: 35.0, lon: 139.0 }],
    roads: [{ id: 'r1', nodeIds: ['n1', 'missing'] }],
  });
  assert.equal(graph.edges.length, 0);
});
