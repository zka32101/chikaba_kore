# Phase 4: お気に入りリストの共有機能 設計

## 背景

Phase 4の新規地図系機能として、施設の「今の混雑状況」共有機能（`docs/PHASE4_CONGESTION_REPORTS_DESIGN.md`）
に続き、「お気に入り（『行きたい』リスト）を他ユーザーへ共有する」機能を追加した。

既存の共有機能（お気に入り画面の「共有」ボタン）はテキスト形式（`Share.share`で施設名の
一覧を送るだけ）に限られており、受け取った側がアプリ内でリストとして閲覧することはできなかった。

## 機能概要

- お気に入り画面の「共有」メニューに「行きたいリストをリンクで共有」を追加
- 「行きたい」リストのスナップショットを`sharedLists`コレクションに保存し、共有コード
  （Firestoreドキュメントの自動生成ID）を発行、`Share.share`でコードを含むテキストを送信
- 受け取った側はアプリ内「共有リストを見る」画面（`/shared-list`）でコードを入力して閲覧
  （ログイン不要、Firestoreの直接読み取り）。各項目から施設詳細画面へ遷移できる

## スコープと判断

- **閲覧専用**: 共有されたリストはそのユーザーのお気に入りには追加されない。追加機能
  （上限チェックとの整合性が必要になる）はスコープ外とし、将来検討とする
- **スナップショット方式**: 共有後に元のお気に入りを更新しても、発行済みの共有リストには
  反映されない（`FavoriteModel`が既に施設情報をスナップショットとして保持しているのと
  同じ考え方）。共有後に相手の表示内容が変わらないことを優先した
- **共有コード = Firestoreドキュメント自動ID**: 短縮URLやQRコードは作らず、コピー&ペースト
  前提のテキスト共有にとどめた。ディープリンク（`chikabamap://shared-list/{id}`等）による
  ワンタップ遷移はネイティブ側の設定変更を伴い、この実行環境でのFlutterビルド確認ができない
  ため見送った。代わりにアプリ内ルート`/shared-list?code=`のクエリパラメータでコードを渡せる
  形にしている（将来Webのディープリンクを足す場合の受け口として）

## データモデル

Firestore `sharedLists`コレクション（トップレベル）:

```
sharedLists/{shareId}
  ownerNickname: string
  items: [{ facilityId, facilityName, facilityThumbnailUrl, facilityCategory }]
  createdAt: Timestamp
```

firestore.rules: 誰でも読み取り可能、作成は認証済みユーザーのみ、作成後の更新・削除は禁止
（スナップショットの不変性を保証）。

## 実装ファイル

- `lib/models/shared_list.dart` — `SharedListItem`/`SharedList`
- `lib/services/shared_list_service.dart` — 抽象インターフェース + Local実装
- `lib/firebase/firebase_shared_list_service.dart` — Firestore実装
- `lib/providers/shared_list_provider.dart` — `sharedListServiceProvider`/`sharedListProvider`/`sharedListCreateNotifierProvider`
- `lib/views/screens/shared_list_screen.dart` — コード入力＋リスト表示画面
- `lib/views/main_tabs/favorite_screen.dart` — 共有メニューに「リンクで共有」「共有リストを見る」を追加
- `lib/config/router.dart` — `/shared-list`ルート追加
- `firestore.rules` — `sharedLists`コレクションのルール追加

Cloud Functions側の変更は無い（クライアント↔Firestore直接のやり取りのみで、連投対策が
必要な書き込み経路ではないため）。

## スコープ外（将来検討）

- 共有リストを自分のお気に入りへ一括追加する機能
- ディープリンク（Web/アプリ間のワンタップ遷移）対応
- 「今行く」リストや、両方を組み合わせた共有
