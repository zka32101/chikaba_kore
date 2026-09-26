import * as admin from 'firebase-admin';

admin.initializeApp();

export { onReviewCreate } from './onReviewCreate';
export { onReviewReportCreate } from './onReviewReportCreate';
export { revenuecatWebhook } from './revenuecatWebhook';

// 安全ルート機能（あんしんみち由来、docs/PHASE3_MODE_INTEGRATION_DESIGN.md参照）
export { onShadeSpotCreated, onBrightnessSpotCreated } from './onSpotCreate';
export { onShadeSpotApproved, onBrightnessSpotApproved } from './onSpotApprove';
export { onSpotCommentCreated } from './onSpotCommentCreate';
export { voteSpot } from './voteSpot';
export { syncVerificationStatus } from './syncVerificationStatus';
export { searchRoute } from './searchRoute';
