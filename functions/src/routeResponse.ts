// 探索結果（ノードidの配列）を、クライアント描画用の区間（辺）内訳に変換する（あんしんみち由来）。
import { RoadGraph } from './routeGraph';

export interface RouteSegment {
  edgeId: string;
  fromLat: number;
  fromLon: number;
  toLat: number;
  toLon: number;
  distanceM: number;
  comfortScore: number;
}

export function buildSegmentBreakdown(graph: RoadGraph, path: string[]): RouteSegment[] {
  const segments: RouteSegment[] = [];
  for (let i = 0; i < path.length - 1; i++) {
    const fromId = path[i];
    const toId = path[i + 1];
    const adjacencyEntry = (graph.adjacency.get(fromId) ?? []).find((e) => e.to === toId);
    if (!adjacencyEntry) continue;

    const from = graph.nodeById.get(fromId);
    const to = graph.nodeById.get(toId);
    if (!from || !to) continue;

    const fullEdge = graph.edgeById.get(adjacencyEntry.edgeId);
    segments.push({
      edgeId: adjacencyEntry.edgeId,
      fromLat: from.lat,
      fromLon: from.lon,
      toLat: to.lat,
      toLon: to.lon,
      distanceM: adjacencyEntry.distanceM,
      comfortScore: fullEdge?.shadowScore ?? 0,
    });
  }
  return segments;
}
