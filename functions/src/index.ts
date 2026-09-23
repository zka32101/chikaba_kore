import * as admin from 'firebase-admin';

admin.initializeApp();

export { onReviewCreate } from './onReviewCreate';
export { onReviewReportCreate } from './onReviewReportCreate';
export { revenuecatWebhook } from './revenuecatWebhook';
