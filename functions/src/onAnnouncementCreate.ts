// お知らせ（announcements/{id}）作成時に`general`トピック購読者へFCM配信する（あんしんみち由来）。
// ドキュメント自体はクライアントから作成不可（firestore.rules参照）。運営が管理コンソール等
// から作成する想定。
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { buildAnnouncementMessage, AnnouncementData } from './announcementNotification';

export const onAnnouncementCreated = functions.firestore
  .document('announcements/{announcementId}')
  .onCreate(async (snap) => {
    const data = snap.data() as AnnouncementData;
    await admin.messaging().send(buildAnnouncementMessage(data));
  });
