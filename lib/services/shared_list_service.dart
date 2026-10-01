import '../models/favorite_model.dart';
import '../models/shared_list.dart';

/// お気に入りリストの共有（作成・取得）の抽象インターフェース。
abstract class SharedListService {
  /// 現在のお気に入りからスナップショットを作成し、共有コード（ドキュメントID）を返す。
  Future<String> createSharedList(String ownerNickname, List<FavoriteModel> favorites);

  /// 共有コードから共有リストを取得する。存在しない場合はnull。
  Future<SharedList?> fetchSharedList(String shareCode);
}

/// Firebase未接続環境向けのフォールバック実装。
class LocalSharedListService implements SharedListService {
  @override
  Future<String> createSharedList(String ownerNickname, List<FavoriteModel> favorites) async =>
      throw UnsupportedError('リストの共有にはFirebase接続が必要です');

  @override
  Future<SharedList?> fetchSharedList(String shareCode) async => null;
}
