// お知らせ（announcements/{id}）作成時に送信するFCMメッセージの組み立て（あんしんみち由来）。
// トピック購読方式を採用しており、個々のユーザーのデバイストークンをサーバー側で管理する
// 必要が無い。既存の「プッシュ通知」設定（`notification_preferences_provider.dart`）が
// 購読/解除する`general`トピックへそのまま配信する（お知らせ専用のトピック・オン/オフは
// 設けず、既存の通知設定に相乗りする）。
export const GENERAL_NOTIFICATION_TOPIC = 'general';

export interface AnnouncementData {
  title?: string;
  body?: string;
}

export interface AnnouncementMessage {
  topic: string;
  notification: {
    title: string;
    body: string;
  };
  data: {
    type: string;
  };
}

export function buildAnnouncementMessage(data: AnnouncementData): AnnouncementMessage {
  return {
    topic: GENERAL_NOTIFICATION_TOPIC,
    notification: {
      title: data.title ?? '近場まっぷからのお知らせ',
      body: data.body ?? '',
    },
    data: {
      type: 'announcement',
    },
  };
}
