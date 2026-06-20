import 'package:flutter/foundation.dart';

import '../../../domain/core/result.dart';

enum UiState { idle, loading, success, error }

abstract class BaseViewModel extends ChangeNotifier {
  UiState _state = UiState.idle;
  DomainError? _lastError;

  UiState get state => _state;
  DomainError? get lastError => _lastError;
  String? get errorMessage =>
      _lastError == null ? null : mapErrorToMessage(_lastError!);
  bool get canRetry => _lastError != null && canRetryError(_lastError);

  @protected
  void startLoading() {
    _state = UiState.loading;
    _lastError = null;
    notifyListeners();
  }

  @protected
  void setResult<T>(Result<T> result) {
    switch (result) {
      case Ok<T>():
        _state = UiState.success;
        _lastError = null;
      case Err<T>(:final error):
        _state = UiState.error;
        _lastError = error;
    }
    notifyListeners();
  }

  Future<void> retry();
}

bool canRetryError(DomainError? error) => canRetry(error);
