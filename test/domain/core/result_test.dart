import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/domain/core/result.dart';

void main() {
  test('Result 可通过穷举 switch 解包', () {
    String unwrap(Result<int> result) => switch (result) {
      Ok<int>(:final value) => 'ok:$value',
      Err<int>(:final error) => 'error:${error.message}',
    };

    expect(unwrap(const Ok(1)), 'ok:1');
    expect(unwrap(const Err(ValidationError('bad'))), 'error:bad');
  });

  test('canRetry 只允许约定的四类错误', () {
    const retryable = <DomainError>[
      SourceUnreachableError(''),
      FileNotFoundError(''),
      NetworkTimeoutError(''),
      MediaLoadError('', mediaType: MediaType.image),
    ];
    const nonRetryable = <DomainError>[
      SourceAuthError(''),
      FileAccessDeniedError(''),
      MediaEncryptedError('', mediaType: MediaType.pdf),
      ValidationError(''),
      OperationCancelledError(),
      InsufficientStorageError(''),
      UnsupportedFormatError('', format: 'rar'),
      DatabaseError(''),
    ];

    expect(retryable.every(canRetry), isTrue);
    expect(nonRetryable.any(canRetry), isFalse);
  });
}
