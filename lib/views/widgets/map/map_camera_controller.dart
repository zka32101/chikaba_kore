import 'package:google_maps_flutter/google_maps_flutter.dart';

/// `GoogleMapController`の薄いラッパー。
/// `GoogleMap.onMapCreated`が呼ばれるまでコントローラがnullな期間を吸収し、
/// 施設探索モード・安全ルートモードの両方から同じAPIでカメラ制御できるようにする
/// （`docs/MAP_COMPONENT_INTEGRATION_DESIGN.md`参照）。
class MapCameraController {
  GoogleMapController? _controller;

  /// `GoogleMap.onMapCreated`から呼び出し、実際のコントローラを受け取る。
  void attach(GoogleMapController controller) {
    _controller = controller;
  }

  /// 指定した1点にカメラを移動する（現在地取得時など）。
  Future<void> animateToPosition(LatLng position, {double zoom = 14.0}) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  /// 指定した範囲全体が収まるようカメラを移動する（ルート全体表示など）。
  Future<void> animateToBounds(LatLngBounds bounds, {double padding = 48.0}) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
