import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// `GoogleMap`に渡す基本オプションのプリセット。
/// 既定値は施設探索モード（自由なズーム・パン操作）を想定しており、
/// 安全ルートモードのような表示専用の用途では`copyWith`で上書きする
/// （`docs/MAP_COMPONENT_INTEGRATION_DESIGN.md`参照）。
class MapBaseOptions {
  const MapBaseOptions({
    this.mapType = MapType.normal,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = true,
    this.zoomControlsEnabled = true,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.mapToolbarEnabled = true,
    this.padding = EdgeInsets.zero,
  });

  final MapType mapType;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool mapToolbarEnabled;
  final EdgeInsets padding;

  /// 安全ルートモードのような「表示のみ・操作抑制」プリセット。
  static const readOnlyPreview = MapBaseOptions(
    zoomControlsEnabled: false,
    zoomGesturesEnabled: false,
    scrollGesturesEnabled: false,
    mapToolbarEnabled: false,
  );

  MapBaseOptions copyWith({
    MapType? mapType,
    bool? myLocationEnabled,
    bool? myLocationButtonEnabled,
    bool? zoomControlsEnabled,
    bool? zoomGesturesEnabled,
    bool? scrollGesturesEnabled,
    bool? mapToolbarEnabled,
    EdgeInsets? padding,
  }) {
    return MapBaseOptions(
      mapType: mapType ?? this.mapType,
      myLocationEnabled: myLocationEnabled ?? this.myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled ?? this.myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled ?? this.zoomControlsEnabled,
      zoomGesturesEnabled: zoomGesturesEnabled ?? this.zoomGesturesEnabled,
      scrollGesturesEnabled: scrollGesturesEnabled ?? this.scrollGesturesEnabled,
      mapToolbarEnabled: mapToolbarEnabled ?? this.mapToolbarEnabled,
      padding: padding ?? this.padding,
    );
  }
}
