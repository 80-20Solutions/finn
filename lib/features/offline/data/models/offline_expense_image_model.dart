import 'package:drift/drift.dart' as drift;
import '../../data/local/offline_database.dart';

/// T110: OfflineExpenseImageModel for receipt images stored locally
///
/// Stores receipt images offline with metadata for later upload
class OfflineExpenseImageModel {
  final OfflineExpenseImage image;

  OfflineExpenseImageModel(this.image);

  /// Create Drift companion for insert
  static OfflineExpenseImagesCompanion toCompanion({
    required String expenseId,
    required String userId,
    required String localPath,
    required int fileSizeBytes,
    String? remoteUrl,
    bool uploaded = false,
  }) {
    return OfflineExpenseImagesCompanion.insert(
      expenseId: expenseId,
      userId: userId,
      localPath: localPath,
      fileSizeBytes: fileSizeBytes,
      remoteUrl: drift.Value(remoteUrl),
      uploaded: drift.Value(uploaded),
      uploadedAt: const drift.Value.absent(),
      localCreatedAt: DateTime.now(),
    );
  }

  /// Mark image as uploaded
  static OfflineExpenseImagesCompanion markUploaded({
    required int imageId,
    required String remoteUrl,
  }) {
    return OfflineExpenseImagesCompanion(
      id: drift.Value(imageId),
      uploaded: const drift.Value(true),
      uploadedAt: drift.Value(DateTime.now()),
      remoteUrl: drift.Value(remoteUrl),
    );
  }

  /// Check if image is within size limit (10MB)
  bool get isWithinSizeLimit => image.fileSizeBytes <= 10 * 1024 * 1024;

  /// Get file size in MB
  double get fileSizeMB => image.fileSizeBytes / (1024 * 1024);

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSizeMB >= 1) {
      return '${fileSizeMB.toStringAsFixed(2)} MB';
    } else {
      final kb = image.fileSizeBytes / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    }
  }
}
