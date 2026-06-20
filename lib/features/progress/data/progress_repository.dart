import '../models/progress_model.dart';

abstract class ProgressRepository {
  Future<List<ProgressModel>> getMyProgress();

  Future<ProgressModel> updateProgress(ProgressModel progress);
}
