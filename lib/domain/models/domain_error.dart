enum MediaType { image, pdf, archive, video }

sealed class DomainError {
  const DomainError(this.message, {this.cause});

  final String message;
  final Object? cause;
}

final class SourceUnreachableError extends DomainError {
  const SourceUnreachableError(super.message, {super.cause});
}

final class SourceAuthError extends DomainError {
  const SourceAuthError(super.message, {super.cause});
}

final class FileNotFoundError extends DomainError {
  const FileNotFoundError(super.message, {super.cause});
}

final class FileAccessDeniedError extends DomainError {
  const FileAccessDeniedError(super.message, {super.cause});
}

final class NetworkTimeoutError extends DomainError {
  const NetworkTimeoutError(super.message, {super.cause});
}

final class MediaLoadError extends DomainError {
  const MediaLoadError(super.message, {super.cause, required this.mediaType});

  final MediaType mediaType;
}

final class MediaEncryptedError extends DomainError {
  const MediaEncryptedError(
    super.message, {
    super.cause,
    required this.mediaType,
  });

  final MediaType mediaType;
}

final class ValidationError extends DomainError {
  const ValidationError(super.message);
}

final class OperationCancelledError extends DomainError {
  const OperationCancelledError([super.message = '操作已取消']);
}

final class InsufficientStorageError extends DomainError {
  const InsufficientStorageError(super.message, {super.cause});
}

final class UnsupportedFormatError extends DomainError {
  const UnsupportedFormatError(
    super.message, {
    super.cause,
    required this.format,
  });

  final String format;
}

final class DatabaseError extends DomainError {
  const DatabaseError(super.message, {super.cause});
}

String mapErrorToMessage(DomainError error) => switch (error) {
  SourceUnreachableError() => '数据源不可达，请检查网络连接',
  SourceAuthError() => 'SMB 认证失败，请检查用户名和密码',
  FileNotFoundError() => '路径不存在或已被移除',
  FileAccessDeniedError() => '权限不足，无法访问该路径',
  NetworkTimeoutError() => '连接超时，请稍后重试',
  MediaLoadError(mediaType: MediaType.pdf) => 'PDF 加载失败',
  MediaLoadError(mediaType: MediaType.archive) => '压缩包读取失败',
  MediaLoadError(mediaType: MediaType.video) => '视频加载失败',
  MediaLoadError() => '图片加载失败',
  MediaEncryptedError(mediaType: MediaType.pdf) => '此 PDF 已加密，暂不支持查看',
  MediaEncryptedError(mediaType: MediaType.archive) => '此压缩包已加密，暂不支持查看',
  MediaEncryptedError(mediaType: MediaType.video) => '此视频已加密，暂不支持查看',
  MediaEncryptedError() => '此文件已加密，暂不支持查看',
  ValidationError(:final message) => message,
  OperationCancelledError() => '操作已取消',
  InsufficientStorageError() => '磁盘空间不足',
  UnsupportedFormatError(:final format) => '不支持的格式: $format',
  DatabaseError() => '数据库异常，请重启应用',
};

bool canRetry(DomainError? error) => switch (error) {
  SourceUnreachableError() ||
  FileNotFoundError() ||
  NetworkTimeoutError() ||
  MediaLoadError() => true,
  _ => false,
};
