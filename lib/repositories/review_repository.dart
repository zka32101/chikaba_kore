import '../models/review_model.dart';
import '../services/firestore_service.dart';

class ReviewRepository {
  final FirestoreService _firestore;
  ReviewRepository(this._firestore);

  Future<List<ReviewModel>> getReviews(String facilityId, {int limit = 10}) =>
      _firestore.getReviews(facilityId, limit: limit);

  Future<void> addReview(ReviewModel review) => _firestore.addReview(review);

  Future<void> reportReview(String reviewId, String userId) =>
      _firestore.reportReview(reviewId, userId);

  Future<List<ReviewModel>> getPendingReviews({int limit = 50}) =>
      _firestore.getPendingReviews(limit: limit);

  Future<void> approveReview(String reviewId) =>
      _firestore.approveReview(reviewId);

  Future<void> rejectReview(String reviewId) =>
      _firestore.rejectReview(reviewId);
}
