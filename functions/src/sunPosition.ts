// NOAA Solar Position Calculatorの簡易版による太陽位置計算（あんしんみち由来）。
import { toRad, toDeg } from './routeGeo';

const RAD = Math.PI / 180;

export interface SunPosition {
  azimuthDeg: number;
  altitudeDeg: number;
}

function julianDay(date: Date): number {
  return date.getTime() / 86_400_000 + 2_440_587.5;
}

/**
 * 指定日時・緯度経度における太陽の方位角（真北=0、東回り）・高度角を計算する。
 * NOAAの簡易アルゴリズムに基づく近似値であり、厳密な天文計算ではない。
 */
export function getSunPosition(date: Date, lat: number, lon: number): SunPosition {
  const jd = julianDay(date);
  const d = jd - 2_451_545.0; // J2000.0からの日数

  const meanLongitude = (280.46 + 0.9856474 * d) % 360;
  const meanAnomaly = (357.528 + 0.9856003 * d) % 360;
  const M = meanAnomaly * RAD;

  const eclipticLongitude =
    meanLongitude +
    1.915 * Math.sin(M) +
    0.02 * Math.sin(2 * M); // 近日点黄経補正C

  const obliquity = 23.4397; // 地軸の傾斜角e
  const lambda = eclipticLongitude * RAD;
  const epsilon = obliquity * RAD;

  const declination = Math.asin(Math.sin(epsilon) * Math.sin(lambda));
  const rightAscension = Math.atan2(Math.cos(epsilon) * Math.sin(lambda), Math.cos(lambda));

  // グリニッジ平均恒星時（度）からその地点の時角を求める
  const gmst = (280.46061837 + 360.98564736629 * d) % 360;
  const localSiderealTime = (gmst + lon) * RAD;
  let hourAngle = localSiderealTime - rightAscension;
  // -180〜180度の範囲に正規化
  hourAngle = ((hourAngle + Math.PI) % (2 * Math.PI)) - Math.PI;

  const latRad = toRad(lat);
  const altitude = Math.asin(
    Math.sin(latRad) * Math.sin(declination) +
      Math.cos(latRad) * Math.cos(declination) * Math.cos(hourAngle)
  );

  const azimuthFromSouth = Math.atan2(
    Math.sin(hourAngle),
    Math.cos(hourAngle) * Math.sin(latRad) - Math.tan(declination) * Math.cos(latRad)
  );
  // 南=0からの角度を、真北=0・東回りの一般的な方位角表記へ変換する
  const azimuthCompassDeg = (toDeg(azimuthFromSouth) + 180 + 360) % 360;

  return { azimuthDeg: azimuthCompassDeg, altitudeDeg: toDeg(altitude) };
}
