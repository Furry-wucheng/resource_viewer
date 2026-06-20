import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/ui/core/view_models/base_view_model.dart';

class TestViewModel extends BaseViewModel {
  int retryCount = 0;

  void load() => startLoading();
  void complete(Result<void> result) => setResult(result);

  @override
  Future<void> retry() async {
    retryCount++;
    startLoading();
  }
}

void main() {
  test('状态迁移和 notifyListeners 次数正确', () async {
    final viewModel = TestViewModel();
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    viewModel.load();
    expect(viewModel.state, UiState.loading);
    expect(notifications, 1);

    viewModel.complete(const Err(NetworkTimeoutError('timeout')));
    expect(viewModel.state, UiState.error);
    expect(viewModel.canRetry, isTrue);
    expect(viewModel.errorMessage, contains('连接超时'));
    expect(notifications, 2);

    await viewModel.retry();
    expect(viewModel.retryCount, 1);
    expect(viewModel.state, UiState.loading);
    expect(notifications, 3);

    viewModel.complete(const Ok(null));
    expect(viewModel.state, UiState.success);
    expect(viewModel.lastError, isNull);
    expect(notifications, 4);
  });
}
