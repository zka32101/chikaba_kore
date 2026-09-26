// 建物の高さ・太陽位置から道路の各区間（辺）の日陰スコアを計算する（あんしんみち由来）。
// 厳密な3D計算ではなく、「建物中心から太陽の反対方向に、建物高さに応じた長さの影が伸びる」
// という平面近似モデルによる簡易版。
import { getSunPosition } from './sunPosition';
import { haversineDistanceM, midpoint, toRad, toDeg, LatLon } from './routeGeo';
import { buildSpatialIndex, itemsWithinBoundingBoxIndexed, SpatialIndex } from './routeSpatialIndex';
import { RoadGraph } from './routeGraph';

const METERS_PER_DEG_LAT = 111320;
const BUILDING_RADIUS_M = 20; // 建物1件あたりの代表半径（足元の広がりの近似）

export interface Building {
  id: string;
  heightM: number;
  center: LatLon;
}

/**
 * グラフの各辺について、指定日時における日陰スコア（0=日陰なし, 1=日陰あり）を計算する。
 * 建物が存在しない場合、または日没後（太陽高度<=0）の場合は全辺0を返す。
 */
export function computeShadowScores(
  graph: RoadGraph,
  buildings: Building[],
  dateTimeUtc: Date
): Map<string, number> {
  const scores = new Map<string, number>();

  if (buildings.length === 0) {
    for (const edge of graph.edges) scores.set(edge.id, 0);
    return scores;
  }

  const sampleNode = graph.nodeById.values().next().value;
  const sunPos = sampleNode ? getSunPosition(dateTimeUtc, sampleNode.lat, sampleNode.lon) : null;

  if (!sunPos || sunPos.altitudeDeg <= 0) {
    for (const edge of graph.edges) scores.set(edge.id, 0);
    return scores;
  }

  // 影は太陽の反対方向（方位角+180度）に伸びる
  const shadowDirectionDeg = (sunPos.azimuthDeg + 180) % 360;
  const altitudeDeg = sunPos.altitudeDeg;

  const buildingById = new Map(buildings.map((b) => [b.id, b]));
  const spatialIndex = buildSpatialIndex(
    buildings.map((b) => ({ id: b.id, lat: b.center[0], lon: b.center[1] }))
  );
  const maxHeightM = Math.max(...buildings.map((b) => b.heightM), 0);
  const maxShadowLengthM = maxHeightM / Math.tan(toRad(altitudeDeg));
  const radiusDeg = (maxShadowLengthM + BUILDING_RADIUS_M) / METERS_PER_DEG_LAT;

  for (const edge of graph.edges) {
    const from = graph.nodeById.get(edge.from);
    const to = graph.nodeById.get(edge.to);
    if (!from || !to) {
      scores.set(edge.id, 0);
      continue;
    }
    const mid = midpoint([from.lat, from.lon], [to.lat, to.lon]);
    const inShadow = isPointInShadow(
      mid,
      spatialIndex,
      buildingById,
      radiusDeg,
      shadowDirectionDeg,
      altitudeDeg
    );
    scores.set(edge.id, inShadow ? 1 : 0);
  }

  return scores;
}

function isPointInShadow(
  point: LatLon,
  spatialIndex: SpatialIndex,
  buildingById: Map<string, Building>,
  radiusDeg: number,
  shadowDirectionDeg: number,
  altitudeDeg: number
): boolean {
  const candidates = itemsWithinBoundingBoxIndexed(spatialIndex, point[0], point[1], radiusDeg);

  for (const candidate of candidates) {
    const building = buildingById.get(candidate.id);
    if (!building) continue;

    const shadowLengthM = building.heightM / Math.tan(toRad(altitudeDeg));
    const distanceM = haversineDistanceM(building.center, point);
    if (distanceM > shadowLengthM + BUILDING_RADIUS_M) continue;

    const bearingToPoint = bearingDeg(building.center, point);
    const angleDiffDeg = angularDifferenceDeg(bearingToPoint, shadowDirectionDeg);
    // 建物の半径分の角度的余裕（近距離ほど広く、遠距離ほど狭く許容する）
    const toleranceDeg = Math.max(5, toDeg(Math.atan2(BUILDING_RADIUS_M, Math.max(distanceM, 1))));
    if (angleDiffDeg <= toleranceDeg) return true;
  }

  return false;
}

/** 2点間の方位角（真北=0、東回り、度） */
function bearingDeg([lat1, lon1]: LatLon, [lat2, lon2]: LatLon): number {
  const phi1 = toRad(lat1);
  const phi2 = toRad(lat2);
  const dLon = toRad(lon2 - lon1);
  const y = Math.sin(dLon) * Math.cos(phi2);
  const x = Math.cos(phi1) * Math.sin(phi2) - Math.sin(phi1) * Math.cos(phi2) * Math.cos(dLon);
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}

/** 2つの方位角の差（0〜180度） */
function angularDifferenceDeg(a: number, b: number): number {
  const diff = Math.abs(a - b) % 360;
  return diff > 180 ? 360 - diff : diff;
}
