import * as admin from 'firebase-admin';

admin.initializeApp();

export { onReviewCreate } from './onReviewCreate';
export { onReviewReportCreate } from './onReviewReportCreate';
export { onReviewHelpfulVoteCreate } from './onReviewHelpfulVoteCreate';
export { onFacilityHiddenGemVoteCreate } from './onFacilityHiddenGemVoteCreate';
export { revenuecatWebhook } from './revenuecatWebhook';

// 安全ルート機能（あんしんみち由来、docs/PHASE3_MODE_INTEGRATION_DESIGN.md参照）
export { onShadeSpotCreated, onBrightnessSpotCreated } from './onSpotCreate';
export { onShadeSpotApproved, onBrightnessSpotApproved } from './onSpotApprove';
export { onSpotCommentCreated } from './onSpotCommentCreate';
export { voteSpot } from './voteSpot';
export { moderateSpot } from './moderateSpot';
export { syncVerificationStatus } from './syncVerificationStatus';
export { searchRoute } from './searchRoute';
export { onAnnouncementCreated } from './onAnnouncementCreate';

// 混雑状況共有（近場まっぷ本体機能、docs/PHASE4_CONGESTION_REPORTS_DESIGN.md参照）
export { submitCongestionReport } from './submitCongestionReport';
