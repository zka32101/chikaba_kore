import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/review_model.dart';
import '../providers/auth_provider.dart';
import '../providers/facility_provider.dart';
import '../services/storage_service.dart';
import '../repositories/review_repository.dart';

class WriteReviewState {
  final int rating;
  final String text;
  final List<File> imageFiles;
  final bool isSubmitting;
  final String? error;
  final bool isSuccess;

  const WriteReviewState({
    this.rating = 0,
    this.text = '',
    this.imageFiles = const [],
    this.isSubmitting = false,
    this.error,
    this.isSuccess = false,
  });

  bool get canSubmit => rating > 0 && text.trim().isNotEmpty && !isSubmitting;

  WriteReviewState copyWith({
    int? rating,
    String? text,
    List<File>? imageFiles,
    bool? isSubmitting,
    Object? error = _sentinel,
    bool? isSuccess,
  }) =>
      WriteReviewState(
        rating: rating ?? this.rating,
        text: text ?? this.text,
        imageFiles: imageFiles ?? this.imageFiles,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error == _sentinel ? this.error : error as String?,
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

const _sentinel = Object();

class WriteReviewViewModel extends StateNotifier<WriteReviewState> {
  final Ref _ref;
  final String _facilityId;
  final _picker = ImagePicker();
  final _storage = StorageService();

  WriteReviewViewModel(this._ref, this._facilityId)
      : super(const WriteReviewState());

  void setRating(int value) => state = state.copyWith(rating: value);
  void setText(String value) => state = state.copyWith(text: value);

  Future<void> pickImages() async {
    if (state.imageFiles.length >= 3) return;
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final remaining = 3 - state.imageFiles.length;
    final newFiles = picked.take(remaining).map((x) => File(x.path)).toList();
    state = state.copyWith(imageFiles: [...state.imageFiles, ...newFiles]);
  }

  void removeImage(int index) {
    final updated = [...state.imageFiles]..removeAt(index);
    state = state.copyWith(imageFiles: updated);
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    final user = _ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      state = state.copyWith(error: 'ログインが必要です');
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      // 画像アップロード
      final imageUrls = <String>[];
      for (final file in state.imageFiles) {
        final url = await _storage.uploadReviewImage(
          facilityId: _facilityId,
          userId: user.uid,
          file: file,
        );
        imageUrls.add(url);
      }

      final review = ReviewModel(
        id: '',
        facilityId: _facilityId,
        userId: user.uid,
        userNickname: user.nickname,
        userType: user.userType,
        rating: state.rating,
        text: state.text.trim(),
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      final reviewRepo = ReviewRepository(
        _ref.read(firestoreServiceProvider),
      );
      await reviewRepo.addReview(review);

      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: '投稿に失敗しました。もう一度お試しください。',
      );
    }
  }
}

final writeReviewViewModelProvider = StateNotifierProvider.autoDispose
    .family<WriteReviewViewModel, WriteReviewState, String>(
  (ref, facilityId) => WriteReviewViewModel(ref, facilityId),
);
