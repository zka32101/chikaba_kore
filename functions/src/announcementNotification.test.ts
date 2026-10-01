import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildAnnouncementMessage, GENERAL_NOTIFICATION_TOPIC } from './announcementNotification';

test('buildAnnouncementMessage: title/bodyをそのまま通知に反映する', () => {
  const message = buildAnnouncementMessage({ title: '新機能リリース', body: '詳細はこちら' });
  assert.equal(message.topic, GENERAL_NOTIFICATION_TOPIC);
  assert.equal(message.notification.title, '新機能リリース');
  assert.equal(message.notification.body, '詳細はこちら');
  assert.equal(message.data.type, 'announcement');
});

test('buildAnnouncementMessage: title/body未設定時はデフォルト値を使う', () => {
  const message = buildAnnouncementMessage({});
  assert.equal(message.notification.title, '近場まっぷからのお知らせ');
  assert.equal(message.notification.body, '');
});
