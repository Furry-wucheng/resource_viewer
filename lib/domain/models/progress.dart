import 'domain_error.dart';

sealed class Progress<T> {
  const Progress();
}

final class ProgressUpdate<T> extends Progress<T> {
  const ProgressUpdate(this.value, this.current, this.total);

  final T value;
  final int current;
  final int total;
}

final class ProgressDone<T> extends Progress<T> {
  const ProgressDone(this.result);

  final T result;
}

final class ProgressError<T> extends Progress<T> {
  const ProgressError(this.error);

  final DomainError error;
}
