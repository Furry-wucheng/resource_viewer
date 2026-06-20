library;

import '../models/domain_error.dart';

export '../models/domain_error.dart';
export '../models/progress.dart';

/// 预期内操作结果。Repository 使用它隔离底层异常。
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final DomainError error;
}
