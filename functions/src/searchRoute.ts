// 日陰・人通りの明るさを考慮した経路探索のCallable Function（あんしんみち由来）。
//
// 道路網・区間スコアはFirestoreから毎回読み込むと重いため、プロセス内メモリに
// `GRAPH_CACHE_TTL_MS`の間キャッシュする（Cloud Functionsのインスタンスが再利用される限り有効）。
// 投稿による区間スコアの集計値（roadSegments）が1件も無い場合は、建物データから
// 日陰スコアを都度計算するフォールバックを使う（seed直後、まだ投稿が無い状態向け）。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { buildGraph, RoadGraph } from './routeGraph';
import { buildSpatialIndex, nearestNodeIdIndexed, SpatialIndex } from './routeSpatialIndex';
import { loadRoadNetworkGeometry, loadBuildings, loadRoadSegmentScores } from './firestoreRoadNetwork';
import { computeShadowScores } from './shadowScore';
import { searchRouteOnGraph } from './routeSearchEngine';
import { buildSegmentBreakdown } from './routeResponse';
import {
  checkAndIncrementRateLimit,
  SEARCH_ROUTE_RATE_LIMIT_WINDOW_MS,
  SEARCH_ROUTE_RATE_LIMIT_MAX_REQUESTS,
} from './spotRateLimiting';

const GRAPH_CACHE_TTL_MS = 5 * 60 * 1000;

interface GraphCache {
  graph: RoadGraph;
  spatialIndex: SpatialIndex;
  loadedAt: number;
}

let graphCache: GraphCache | null = null;

async function loadCachedGraph(db: admin.firestore.Firestore): Promise<GraphCache> {
  const now = Date.now();
  if (graphCache && now - graphCache.loadedAt < GRAPH_CACHE_TTL_MS) {
    return graphCache;
  }

  const { nodes, roads } = await loadRoadNetworkGeometry(db);
  const graph = buildGraph({ nodes, roads });
  const spatialIndex = buildSpatialIndex(graph.nodeById.values());

  const scores = await loadRoadSegmentScores(db);
  if (scores.size > 0) {
    for (const edge of graph.edges) {
      edge.shadowScore = scores.get(edge.id) ?? 0;
    }
  } else {
    const buildings = await loadBuildings(db);
    const shadowScores = computeShadowScores(graph, buildings, new Date());
    for (const edge of graph.edges) {
      edge.shadowScore = shadowScores.get(edge.id) ?? 0;
    }
  }

  graphCache = { graph, spatialIndex, loadedAt: now };
  return graphCache;
}

export const searchRoute = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'サインインが必要です');
  }

  const db = admin.firestore();
  const allowed = await checkAndIncrementRateLimit(db, `searchRoute:${context.auth.uid}`, {
    windowMs: SEARCH_ROUTE_RATE_LIMIT_WINDOW_MS,
    maxRequests: SEARCH_ROUTE_RATE_LIMIT_MAX_REQUESTS,
    now: new Date(),
  });
  if (!allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      '短時間に検索が集中しています。しばらく待ってから再度お試しください'
    );
  }

  const { originLat, originLon, destLat, destLon, shadeWeight } = data ?? {};
  if ([originLat, originLon, destLat, destLon].some((v) => typeof v !== 'number')) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'originLat/originLon/destLat/destLonは数値で指定してください'
    );
  }

  const { graph, spatialIndex } = await loadCachedGraph(db);
  if (graph.nodeById.size === 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      '道路網データが投入されていません（seed未実施の可能性）'
    );
  }

  const originId = nearestNodeIdIndexed(spatialIndex, originLat, originLon);
  const destId = nearestNodeIdIndexed(spatialIndex, destLat, destLon);
  if (!originId || !destId) {
    throw new functions.https.HttpsError('not-found', '指定地点付近に道路網データが見つかりませんでした');
  }

  const shadowScores = new Map(graph.edges.map((e) => [e.id, e.shadowScore ?? 0]));
  const result = searchRouteOnGraph(graph, shadowScores, originId, destId, {
    shadeWeight: typeof shadeWeight === 'number' ? shadeWeight : 0.6,
  });
  if (!result) {
    throw new functions.https.HttpsError('not-found', '指定地点間の経路が見つかりませんでした');
  }

  return {
    path: result.path,
    distanceM: result.distanceM,
    cost: result.cost,
    nodes: result.path.map((id) => {
      const n = graph.nodeById.get(id);
      return { id, lat: n?.lat, lon: n?.lon };
    }),
    segments: buildSegmentBreakdown(graph, result.path),
  };
});
