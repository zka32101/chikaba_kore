// 座標計算の共通ユーティリティ（Haversine距離、度→ラジアン変換等、あんしんみち由来）。
export type LatLon = [number, number];

const EARTH_RADIUS_M = 6_371_000;

export function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

export function toDeg(rad: number): number {
  return (rad * 180) / Math.PI;
}

/** 2点間の距離（メートル） */
export function haversineDistanceM([lat1, lon1]: LatLon, [lat2, lon2]: LatLon): number {
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_M * c;
}

/** 2点の中点（単純平均。区間程度の短距離であれば十分な近似） */
export function midpoint([lat1, lon1]: LatLon, [lat2, lon2]: LatLon): LatLon {
  return [(lat1 + lat2) / 2, (lon1 + lon2) / 2];
}
