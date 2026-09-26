// 道路網（ノード・道路）から経路探索用のグラフを構築する（あんしんみち由来）。
import { haversineDistanceM, LatLon } from './routeGeo';

export interface RoadNode {
  id: string;
  lat: number;
  lon: number;
}

export interface RoadWay {
  id: string;
  name?: string | null;
  nodeIds: string[];
}

export interface RoadEdge {
  id: string;
  roadId: string;
  from: string;
  to: string;
  distanceM: number;
  shadowScore?: number;
}

export interface RoadGraphAdjacencyEntry {
  to: string;
  edgeId: string;
  distanceM: number;
}

export interface RoadGraph {
  nodeById: Map<string, RoadNode>;
  adjacency: Map<string, RoadGraphAdjacencyEntry[]>;
  edges: RoadEdge[];
  edgeById: Map<string, RoadEdge>;
}

/** 道路ごとのノード列を隣接ノード同士の辺（両方向）に分解し、探索用グラフを構築する */
export function buildGraph({ nodes, roads }: { nodes: RoadNode[]; roads: RoadWay[] }): RoadGraph {
  const nodeById = new Map(nodes.map((n) => [n.id, n]));
  const adjacency = new Map<string, RoadGraphAdjacencyEntry[]>(nodes.map((n) => [n.id, []]));
  const edges: RoadEdge[] = [];

  for (const road of roads) {
    for (let i = 0; i < road.nodeIds.length - 1; i++) {
      const fromId = road.nodeIds[i];
      const toId = road.nodeIds[i + 1];
      const from = nodeById.get(fromId);
      const to = nodeById.get(toId);
      if (!from || !to) continue;

      const distanceM = haversineDistanceM([from.lat, from.lon] as LatLon, [to.lat, to.lon] as LatLon);
      const edgeId = `${road.id}_${i}`;
      edges.push({ id: edgeId, roadId: road.id, from: fromId, to: toId, distanceM });
      adjacency.get(fromId)?.push({ to: toId, edgeId, distanceM });
      adjacency.get(toId)?.push({ to: fromId, edgeId, distanceM });
    }
  }

  return { nodeById, adjacency, edges, edgeById: new Map(edges.map((e) => [e.id, e])) };
}
