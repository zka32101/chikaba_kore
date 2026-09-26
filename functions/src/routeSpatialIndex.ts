// 最近傍ノード探索を高速化するための空間インデックス（グリッド分割、あんしんみち由来）。
export interface SpatialIndexNode {
  id: string;
  lat: number;
  lon: number;
}

export interface SpatialIndex {
  cellSizeDeg: number;
  cells: Map<string, SpatialIndexNode[]>;
  bbox: { minCx: number; maxCx: number; minCy: number; maxCy: number };
}

const DEFAULT_CELL_SIZE_DEG = 0.005; // 東京付近で概ね500m四方

function cellKey(cx: number, cy: number): string {
  return `${cx}:${cy}`;
}

export function buildSpatialIndex(
  nodes: Iterable<SpatialIndexNode>,
  cellSizeDeg: number = DEFAULT_CELL_SIZE_DEG
): SpatialIndex {
  const cells = new Map<string, SpatialIndexNode[]>();
  let minCx = Infinity;
  let maxCx = -Infinity;
  let minCy = Infinity;
  let maxCy = -Infinity;

  for (const node of nodes) {
    const cx = Math.floor(node.lon / cellSizeDeg);
    const cy = Math.floor(node.lat / cellSizeDeg);
    const key = cellKey(cx, cy);
    const bucket = cells.get(key);
    if (bucket) {
      bucket.push(node);
    } else {
      cells.set(key, [node]);
    }
    if (cx < minCx) minCx = cx;
    if (cx > maxCx) maxCx = cx;
    if (cy < minCy) minCy = cy;
    if (cy > maxCy) maxCy = cy;
  }

  return { cellSizeDeg, cells, bbox: { minCx, maxCx, minCy, maxCy } };
}

/** 中心セルから外側へリング状にオフセットを生成する（(0,0), 次に半径1のリング全体, ...） */
function* ringOffsets(ring: number): Generator<[number, number]> {
  if (ring === 0) {
    yield [0, 0];
    return;
  }
  for (let dx = -ring; dx <= ring; dx++) {
    yield [dx, -ring];
    yield [dx, ring];
  }
  for (let dy = -ring + 1; dy <= ring - 1; dy++) {
    yield [-ring, dy];
    yield [ring, dy];
  }
}

/**
 * 指定座標に最も近いノードのidを返す。中心セルから外側へリング状に走査半径を広げ、
 * 候補が見つかりそれ以上のリングでは絶対に更新されないと判断できる時点で打ち切る。
 */
export function nearestNodeIdIndexed(index: SpatialIndex, lat: number, lon: number): string | null {
  const { cellSizeDeg, cells, bbox } = index;
  if (cells.size === 0) return null; // ノードが1件も無い場合はbboxがInfinityとなり探索できない

  const cx = Math.floor(lon / cellSizeDeg);
  const cy = Math.floor(lat / cellSizeDeg);

  let bestId: string | null = null;
  let bestDistSq = Infinity;

  const distToBox =
    Math.max(bbox.minCx - cx, 0, cx - bbox.maxCx) + Math.max(bbox.minCy - cy, 0, cy - bbox.maxCy);
  const boxSpan = Math.max(bbox.maxCx - bbox.minCx, bbox.maxCy - bbox.minCy, 0);
  const maxRing = distToBox + boxSpan + 1;

  for (let ring = 0; ring <= maxRing; ring++) {
    // 既に候補が見つかっており、このリングの最小到達距離が現在のベストを超えているなら、
    // これ以降のリングも同様に更新できないため打ち切る（半径ringのセルの外周は少なくとも
    // (ring-1)*cellSizeDeg以上離れている、という保守的な下限を使う）。
    if (bestId !== null && ring > 1) {
      const minPossibleDistDeg = (ring - 1) * cellSizeDeg;
      if (minPossibleDistDeg * minPossibleDistDeg > bestDistSq) break;
    }

    for (const [dx, dy] of ringOffsets(ring)) {
      const bucket = cells.get(cellKey(cx + dx, cy + dy));
      if (!bucket) continue;
      for (const node of bucket) {
        const dLat = node.lat - lat;
        const dLon = node.lon - lon;
        const distSq = dLat * dLat + dLon * dLon;
        if (distSq < bestDistSq) {
          bestDistSq = distSq;
          bestId = node.id;
        }
      }
    }
  }

  return bestId;
}

/** 正方形バウンディングボックス内の候補ノードを返す（緩いが漏れの無いフィルタ） */
export function itemsWithinBoundingBoxIndexed(
  index: SpatialIndex,
  lat: number,
  lon: number,
  radiusDeg: number
): SpatialIndexNode[] {
  const { cellSizeDeg, cells } = index;
  const minCx = Math.floor((lon - radiusDeg) / cellSizeDeg);
  const maxCx = Math.floor((lon + radiusDeg) / cellSizeDeg);
  const minCy = Math.floor((lat - radiusDeg) / cellSizeDeg);
  const maxCy = Math.floor((lat + radiusDeg) / cellSizeDeg);

  const results: SpatialIndexNode[] = [];
  for (let cx = minCx; cx <= maxCx; cx++) {
    for (let cy = minCy; cy <= maxCy; cy++) {
      const bucket = cells.get(cellKey(cx, cy));
      if (!bucket) continue;
      for (const node of bucket) {
        if (Math.abs(node.lat - lat) <= radiusDeg && Math.abs(node.lon - lon) <= radiusDeg) {
          results.push(node);
        }
      }
    }
  }
  return results;
}
