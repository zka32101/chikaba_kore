enum SubscriptionTier { free, premium }

/// RevenueCat の CustomerInfo から導出するサブスクリプション状態。
/// 姉妹アプリ「あんしんみち」(project-039) の subscription_state.dart と同じ語彙。
class SubscriptionState {
  final SubscriptionTier tier;
  final DateTime? expiresAt;

  const SubscriptionState({required this.tier, this.expiresAt});

  static const free = SubscriptionState(tier: SubscriptionTier.free);

  bool get isPremium => tier == SubscriptionTier.premium;
}
