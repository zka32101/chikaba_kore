import 'package:flutter/material.dart';

/// 安心スコア(0〜1)を「影濃い緑〜明るい黄」のグラデーションへ変換する。
/// project-039（あんしんみち）の`AppTheme.comfortScoreColor`と同じ配色。
/// 近場まっぷ側で将来スコア可視化（穴場度等）が増えた際にも流用できるよう、
/// テーマクラスに依存しない単独関数として切り出している
/// （`docs/MAP_COMPONENT_INTEGRATION_DESIGN.md`参照）。
Color comfortScoreColor(double score) {
  final clamped = score.clamp(0.0, 1.0);
  return Color.lerp(const Color(0xFFFFF176), const Color(0xFF1B5E20), clamped)!;
}
