import '../models/review_model.dart';
import '../services/firestore_service.dart';

class ReviewRepository {
  final FirestoreService _firestore;
  ReviewRepository(this._firestore);

  Future<List<ReviewModel>> getReviews(String facilityId, {int limit = 10}) =>
      _firestore.getReviews(facilityId, limit: limit);

  Future<void> addReview(ReviewModel review) => _firestore.addReview(review);
}
