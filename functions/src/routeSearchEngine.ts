// 日陰重み付きDijkstra法による経路探索（あんしんみち由来）。
import { MinHeap } from './routeMinHeap';
import { RoadGraph } from './routeGraph';

export interface RouteSearchResult {
  path: string[];
  distanceM: number;
  cost: number;
}

export interface RouteWeightPrefs {
  shadeWeight?: number;
}

/**
 * `shadowScores`（edgeId→0..1の日陰スコア）で辺のコストを重み付けしたDijkstra法。
 * `shadeWeight`が大きいほど日陰の多い経路を優先する（0で最短距離のみ、1で日陰スコア1の辺のコストを0にする）。
 */
export function searchRouteOnGraph(
  graph: RoadGraph,
  shadowScores: Map<string, number>,
  originNodeId: string,
  destNodeId: string,
  weightPrefs: RouteWeightPrefs = {}
): RouteSearchResult | null {
  const shadeWeight = weightPrefs.shadeWeight ?? 0.5;

  if (!graph.nodeById.has(originNodeId) || !graph.nodeById.has(destNodeId)) return null;

  const edgeById = graph.edgeById ?? new Map(graph.edges.map((e) => [e.id, e]));
  const dist = new Map<string, number>([[originNodeId, 0]]);
  const prevEdge = new Map<string, string>();
  const prevNode = new Map<string, string>();
  const visited = new Set<string>();
  const heap = new MinHeap<string>();
  heap.push(originNodeId, 0);

  while (!heap.isEmpty()) {
    const popped = heap.pop();
    if (!popped) break;
    const current = popped.item;
    const currentCost = popped.priority;
    if (visited.has(current)) continue;
    visited.add(current);
    if (current === destNodeId) break;

    const neighbors = graph.adjacency.get(current) ?? [];
    for (const { to, edgeId, distanceM } of neighbors) {
      if (visited.has(to)) continue;
      const shadowScore = shadowScores.get(edgeId) ?? 0;
      const edgeCost = distanceM * (1 - shadeWeight * shadowScore);
      const newCost = currentCost + edgeCost;
      if (newCost < (dist.get(to) ?? Infinity)) {
        dist.set(to, newCost);
        prevEdge.set(to, edgeId);
        prevNode.set(to, current);
        heap.push(to, newCost);
      }
    }
  }

  if (!dist.has(destNodeId)) return null;

  const path = [destNodeId];
  let cur = destNodeId;
  let distanceM = 0;
  while (cur !== originNodeId) {
    const edgeId = prevEdge.get(cur);
    const prev = prevNode.get(cur);
    if (!edgeId || !prev) {
      console.error(`searchRouteOnGraph: 経路復元に失敗しました（cur=${cur}）`);
      return null;
    }
    const edge = edgeById.get(edgeId);
    if (!edge) {
      console.error(`searchRouteOnGraph: 辺が見つかりません（edgeId=${edgeId}）`);
      return null;
    }
    distanceM += edge.distanceM ?? 0;
    path.push(prev);
    cur = prev;
  }
  path.reverse();

  return { path, distanceM, cost: dist.get(destNodeId) as number };
}
