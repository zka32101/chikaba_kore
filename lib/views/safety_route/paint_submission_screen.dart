import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/spot_submission.dart';
import '../../models/spot_type.dart';
import '../../models/user_profile.dart';
import '../../providers/location_provider.dart';
import '../../providers/spot_provider.dart';
import '../../providers/verification_provider.dart';
import '../../services/spot_submission_service.dart';
import '../../utils/constants.dart';
import '../widgets/checkmark_burst_animation.dart';
import '../widgets/primary_button.dart';
import 'phone_verification_screen.dart';
import 'widgets/spot_type_selector.dart';

enum _PaintStep { typeSelection, drawing, confirming, submitting, success }

/// 投稿フロー（設計書Step2「投稿フロー」に対応）:
/// 種別選択 → 実地図を指でなぞる → 歩道エッジへ自動スナップ →
/// [本人確認済みユーザーのみ] コメント追加可 → 投稿完了（反映モードにより即時反映/承認待ち表示）
///
/// project-039（あんしんみち）は模式図キャンバス（`MapProjection`）上でなぞる方式だったが、
/// 近場まっぷは「実地図のみ」方針（`docs/MAP_COMPONENT_INTEGRATION_DESIGN.md`）のため、
/// 実際のGoogleMap上でなぞる方式に再設計している。
class PaintSubmissionScreen extends ConsumerStatefulWidget {
  const PaintSubmissionScreen({super.key});

  @override
  ConsumerState<PaintSubmissionScreen> createState() => _PaintSubmissionScreenState();
}

class _PaintSubmissionScreenState extends ConsumerState<PaintSubmissionScreen> {
  _PaintStep _step = _PaintStep.typeSelection;
  GoogleMapController? _mapController;
  SpotType? _selectedType;
  final List<LatLng> _tracePoints = [];
  List<({double lat, double lon})>? _confirmedTrace;
  ReflectMode? _resultReflectMode;
  String? _errorMessage;
  UserProfile _profile = UserProfile.unverified;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(verificationServiceProvider).getProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _openVerification() async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
    );
    if (verified == true) await _loadProfile();
  }

  void _selectType(SpotType type) {
    setState(() {
      _selectedType = type;
      _step = _PaintStep.drawing;
    });
  }

  Future<void> _handlePanUpdate(DragUpdateDetails details, BuildContext canvasContext) async {
    final controller = _mapController;
    if (controller == null) return;
    final box = canvasContext.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final latLng = await controller.getLatLng(
      ScreenCoordinate(
        x: (local.dx * devicePixelRatio).round(),
        y: (local.dy * devicePixelRatio).round(),
      ),
    );
    if (!mounted) return;
    setState(() => _tracePoints.add(latLng));
  }

  void _handlePanEnd() {
    if (_tracePoints.length < 2) {
      setState(_tracePoints.clear);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _confirmedTrace = _tracePoints.map((p) => (lat: p.latitude, lon: p.longitude)).toList();
      _step = _PaintStep.confirming;
    });
  }

  void _backToDrawing() {
    setState(() {
      _tracePoints.clear();
      _confirmedTrace = null;
      _step = _PaintStep.drawing;
    });
  }

  Future<void> _confirmSubmit() async {
    final trace = _confirmedTrace;
    final type = _selectedType;
    if (trace == null || type == null) return;

    setState(() {
      _step = _PaintStep.submitting;
      _errorMessage = null;
    });

    try {
      final comment = _profile.isVerified && _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null;
      final result = await ref.read(spotSubmissionServiceProvider).submitSpot(
            trace: trace,
            type: type,
            comment: comment,
          );

      if (!mounted) return;
      setState(() {
        _resultReflectMode = result.reflectMode;
        _step = _PaintStep.success;
      });
    } on SpotSubmissionException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _step = _PaintStep.drawing;
        _tracePoints.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '投稿に失敗しました。もう一度お試しください';
        _step = _PaintStep.drawing;
        _tracePoints.clear();
      });
    }
  }

  Set<Polyline> _buildPolylines() {
    if (_step == _PaintStep.drawing && _tracePoints.length > 1) {
      return {
        Polyline(
          polylineId: const PolylineId('drawing_trace'),
          points: _tracePoints,
          color: (_selectedType?.color ?? Colors.blue).withValues(alpha: 0.85),
          width: 6,
        ),
      };
    }
    final confirmed = _confirmedTrace;
    if ((_step == _PaintStep.confirming || _step == _PaintStep.submitting) && confirmed != null) {
      return {
        Polyline(
          polylineId: const PolylineId('confirmed_trace'),
          points: confirmed.map((p) => LatLng(p.lat, p.lon)).toList(),
          color: _selectedType?.color ?? Colors.blue,
          width: 6,
        ),
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    final isDrawing = _step == _PaintStep.drawing;

    return Scaffold(
      appBar: AppBar(title: const Text('塗って投稿')),
      body: Stack(
        children: [
          Builder(
            builder: (canvasContext) => Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: locationAsync.valueOrNull != null
                        ? LatLng(locationAsync.valueOrNull!.latitude, locationAsync.valueOrNull!.longitude)
                        : const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
                    zoom: 17,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  polylines: _buildPolylines(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: !isDrawing,
                  // なぞっている間は地図自体のジェスチャーを止め、Panを軌跡入力に使う
                  scrollGesturesEnabled: !isDrawing,
                  zoomGesturesEnabled: !isDrawing,
                  rotateGesturesEnabled: !isDrawing,
                  tiltGesturesEnabled: !isDrawing,
                ),
                if (isDrawing)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (details) => _handlePanUpdate(details, canvasContext),
                      onPanEnd: (_) => _handlePanEnd(),
                    ),
                  ),
              ],
            ),
          ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    switch (_step) {
      case _PaintStep.typeSelection:
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _OverlayCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('何を投稿しますか？', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('道の様子を選んでください'),
                const SizedBox(height: 16),
                SpotTypeSelector(selected: null, onSelected: _selectType),
              ],
            ),
          ),
        );
      case _PaintStep.drawing:
        return Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: _OverlayCard(
            child: Row(
              children: [
                Icon(_selectedType!.icon, color: _selectedType!.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedType!.label}を、指で道になぞってください',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _step = _PaintStep.typeSelection),
                  child: const Text('種別を変更'),
                ),
              ],
            ),
          ),
        );
      case _PaintStep.confirming:
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _OverlayCard(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: _selectedType!.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('このなぞり方でよろしいですか？', style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 12),
                  if (_profile.isVerified)
                    TextField(
                      controller: _commentController,
                      maxLength: 140,
                      decoration: const InputDecoration(
                        labelText: 'コメント（任意）',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('本人確認をするとコメントを追加できます'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openVerification,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: _backToDrawing, child: const Text('やり直す')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(label: 'この道に投稿する', onPressed: _confirmSubmit),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      case _PaintStep.submitting:
        return const Positioned.fill(
          child: Center(child: CircularProgressIndicator()),
        );
      case _PaintStep.success:
        final isImmediate = _resultReflectMode == ReflectMode.immediate;
        return Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckmarkBurstAnimation(color: _selectedType?.color ?? Colors.blue),
                  const SizedBox(height: 20),
                  Text(
                    isImmediate ? '地図に反映されました！' : '投稿ありがとうございます',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      isImmediate
                          ? 'あなたの投稿が、次にここを歩く誰かの安心につながります'
                          : '内容を確認のうえ、順次地図へ反映します（承認待ち）',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: '地図に戻る',
                    onPressed: () async => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _OverlayCard extends StatelessWidget {
  final Widget child;
  const _OverlayCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
