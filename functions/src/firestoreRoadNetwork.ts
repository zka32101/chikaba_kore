// 道路網（ノード・道路・建物・区間スコア）をFirestoreから読み込む（あんしんみち由来）。
// コレクション構成:
//   roadNodes/{id}    = { lat, lon }
//   roadWays/{id}     = { name?, nodeIds: string[] }
//   roadSegments/{id} = { roadId, fromNodeId, toNodeId, distanceM, baseShadowScore,
//                          aggregatedShadeScore, aggregatedBrightnessScore, lastCalculatedAt }
//   buildings/{id}    = { heightM, centerLat, centerLon }
import * as admin from 'firebase-admin';
import { RoadNode, RoadWay } from './routeGraph';
import { Building } from './shadowScore';

export async function loadRoadNetworkGeometry(
  db: admin.firestore.Firestore
): Promise<{ nodes: RoadNode[]; roads: RoadWay[] }> {
  const [nodesSnap, waysSnap] = await Promise.all([
    db.collection('roadNodes').get(),
    db.collection('roadWays').get(),
  ]);
  const nodes: RoadNode[] = nodesSnap.docs.map((doc) => ({
    id: doc.id,
    lat: doc.data().lat as number,
    lon: doc.data().lon as number,
  }));
  const roads: RoadWay[] = waysSnap.docs.map((doc) => ({
    id: doc.id,
    name: (doc.data().name as string | undefined) ?? null,
    nodeIds: (doc.data().nodeIds as string[] | undefined) ?? [],
  }));
  return { nodes, roads };
}

export async function loadBuildings(db: admin.firestore.Firestore): Promise<Building[]> {
  const snap = await db.collection('buildings').get();
  return snap.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      heightM: data.heightM as number,
      center: [data.centerLat as number, data.centerLon as number],
    };
  });
}

/**
 * 区間（roadSegments）ごとの快適スコア（0〜1、日陰＋人通りの明るさの平均）を読み込む。
 * 投稿による集計値（aggregatedShadeScore）が無い場合はベース値（baseShadowScore、建物影の
 * 事前計算結果）にフォールバックする。
 */
export async function loadRoadSegmentScores(
  db: admin.firestore.Firestore
): Promise<Map<string, number>> {
  const snap = await db.collection('roadSegments').get();
  const scores = new Map<string, number>();
  for (const doc of snap.docs) {
    const d = doc.data();
    const shade = d.aggregatedShadeScore > 0 ? d.aggregatedShadeScore : (d.baseShadowScore ?? 0);
    const brightness = d.aggregatedBrightnessScore ?? 0;
    const comfortScore = Math.min(1, Math.max(0, (shade + brightness) / 2));
    scores.set(doc.id, comfortScore);
  }
  return scores;
}
