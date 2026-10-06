# Phase 4: 施設の営業時間ベース通知 設計

## 背景

お気に入り（「行きたい」リスト）に登録した施設の営業時間は施設詳細画面で
確認できるが、開店・閉店のタイミングをユーザーが覚えて訪問する必要があった。
お気に入り施設の開店・閉店が近づいたら端末内のローカル通知で知らせる機能を
追加する。

既存のプッシュ通知（FCM、`notification_preferences_provider.dart`）とは
別の仕組みとして実装する。営業時間は施設ごと・曜日ごとに異なり、サーバー側で
全ユーザー分の通知タイミングを一括管理するより、各端末がローカルで
`flutter_local_notifications`を使って予約するほうが単純で、新規の
Cloud Functions・Firestoreコレクションも不要になる。

## 実装方針

### 営業時間のパース

`FacilityModel.businessHours`は`Map<String, String>`（キー: 曜日の漢字一文字、
値: `"09:00-18:00"`形式の文字列、または「定休日」等の非時刻文字列）。
`lib/utils/business_hours_parser.dart`の`parseBusinessHoursRange()`で
`"HH:MM-HH:MM"`形式のみをパースし、それ以外（定休日表記や不正な値）は
nullを返して通知対象から除外する。

### 通知のスケジューリング

`BusinessHoursNotificationNotifier`
（`lib/providers/business_hours_notification_provider.dart`）が、
「行きたい」リスト（`wantToGoProvider`）の各施設について、今日の曜日の
営業時間から開店15分前・閉店30分前の時刻を計算し、
`NotificationService.scheduleLocalNotification()`で端末内通知を予約する。
通知IDは`facilityId.hashCode`から開店・閉店それぞれ別のint32 IDを生成する
（`_notificationId`）。

`NotificationService`（既存、`lib/services/notification_service.dart`）に
`scheduleLocalNotification`/`cancelLocalNotification`を追加した。
`flutter_local_notifications`の`zonedSchedule`はタイムゾーン付きの絶対時刻
（`timezone`パッケージの`TZDateTime`）を要求するため、渡されたローカル時刻を
UTCに変換してから`TZDateTime.utc()`で構築することで、端末のタイムゾーン
ロケール設定（`tz.setLocalLocation`）に依存せず正確な絶対時刻として予約する。
`AndroidScheduleMode.inexactAllowWhileIdle`を使い、`SCHEDULE_EXACT_ALARM`
権限（Android 12+で必要）を要求しない（多少の遅延が許容できる通知のため）。

### 再計算のタイミング

お気に入り画面（`FavoriteScreen`）を開くたびに
`BusinessHoursNotificationNotifier.reschedule()`を呼び、その日の最新の
お気に入りリストと営業時間に基づいて通知を再予約する（一度全キャンセルして
から再構築する単純な設計）。アプリ起動時の自動予約は行わず、ユーザーが
お気に入り画面を一度開くまでは通知されない制約がある（スコープ外として
明記）。

### ON/OFF設定

既存の「プッシュ通知」トグルとは独立した「営業時間通知」トグルを
マイページの通知セクションに追加した（`settings_screen.dart`）。デフォルトは
OFF（オプトイン方式）。Hiveの`user`ボックスに
`business_hours_notifications_enabled`として保存する（既存の
`notifications_enabled`と同じパターン）。OFFにした時点で現在のお気に入り
施設分の通知をキャンセルする。

## 実装ファイル

- `pubspec.yaml` — `timezone`パッケージを追加（`flutter_local_notifications`の
  推移的依存だったものを直接依存に明示）
- `lib/utils/business_hours_parser.dart` — 営業時間文字列のパーサー（新規）
- `lib/services/notification_service.dart` — `scheduleLocalNotification`/
  `cancelLocalNotification`、タイムゾーンデータの初期化
- `lib/providers/business_hours_notification_provider.dart` —
  `BusinessHoursNotificationNotifier`（新規）
- `lib/views/main_tabs/favorite_screen.dart` — 画面表示時に`reschedule()`を呼ぶ
- `lib/views/main_tabs/settings_screen.dart` — 「営業時間通知」トグルを追加

バックエンド（Cloud Functions、firestore.rules）の変更は無い（既存の
`facilities`コレクションの読み取りのみ）。

## スコープ外（将来検討）

- アプリ起動時・バックグラウンドでの自動再計算（現状はお気に入り画面を
  開いたタイミングのみ）
- 通知タイミング（15分前/30分前）をユーザーが変更できる設定
- 通知タップ時の施設詳細画面への遷移（ローカル通知のタップハンドラは未実装）
- 翌日以降の営業時間の先読み予約（現状は「今日」の分のみ）
