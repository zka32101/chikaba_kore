import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildGraph } from './routeGraph';
import { searchRouteOnGraph } from './routeSearchEngine';

function buildLineGraph() {
  // n1 - n2 - n3 の一直線（各区間は緯度0.001度差、概ね111m）
  return buildGraph({
    nodes: [
      { id: 'n1', lat: 35.0, lon: 139.0 },
      { id: 'n2', lat: 35.001, lon: 139.0 },
      { id: 'n3', lat: 35.002, lon: 139.0 },
    ],
    roads: [{ id: 'r1', nodeIds: ['n1', 'n2', 'n3'] }],
  });
}

test('searchRouteOnGraph: 直線経路をn1からn3まで探索できる', () => {
  const graph = buildLineGraph();
  const result = searchRouteOnGraph(graph, new Map(), 'n1', 'n3');
  assert.deepEqual(result?.path, ['n1', 'n2', 'n3']);
  assert.ok((result?.distanceM ?? 0) > 0);
});

test('searchRouteOnGraph: 存在しないノードを指定するとnull', () => {
  const graph = buildLineGraph();
  assert.equal(searchRouteOnGraph(graph, new Map(), 'n1', 'missing'), null);
});

test('searchRouteOnGraph: 到達不能なノードはnull', () => {
  const graph = buildGraph({
    nodes: [
      { id: 'a', lat: 35.0, lon: 139.0 },
      { id: 'b', lat: 36.0, lon: 140.0 },
    ],
    roads: [],
  });
  assert.equal(searchRouteOnGraph(graph, new Map(), 'a', 'b'), null);
});

test('searchRouteOnGraph: shadeWeightが高いほど日陰の多い迂回路のコストが下がる', () => {
  // n1 - n2 - n3（直線、日陰なし）と、n1 - n4 - n3（迂回、全区間日陰あり）の2経路
  const graph = buildGraph({
    nodes: [
      { id: 'n1', lat: 35.0, lon: 139.0 },
      { id: 'n2', lat: 35.001, lon: 139.0 },
      { id: 'n3', lat: 35.002, lon: 139.0 },
      { id: 'n4', lat: 35.001, lon: 139.002 },
    ],
    roads: [
      { id: 'straight', nodeIds: ['n1', 'n2', 'n3'] },
      { id: 'detour', nodeIds: ['n1', 'n4', 'n3'] },
    ],
  });
  const shadowScores = new Map<string, number>([
    ['detour_0', 1],
    ['detour_1', 1],
  ]);

  const noShade = searchRouteOnGraph(graph, shadowScores, 'n1', 'n3', { shadeWeight: 0 });
  assert.deepEqual(noShade?.path, ['n1', 'n2', 'n3']); // 最短距離である直線を選ぶ

  const fullShade = searchRouteOnGraph(graph, shadowScores, 'n1', 'n3', { shadeWeight: 1 });
  assert.deepEqual(fullShade?.path, ['n1', 'n4', 'n3']); // 日陰優先で迂回路を選ぶ
});
