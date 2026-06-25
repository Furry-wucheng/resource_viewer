import 'dart:async';
import 'dart:io';
import 'dart:isolate';

/// 简单的 Isolate 并发池（信号量模式）。
///
/// 限制同时运行的 [Isolate.run] 数量，超出时排队等待。
/// 默认并发数 = CPU 核心数（上限 4）。
class IsolatePool {
  IsolatePool({int? maxConcurrency})
      : _maxConcurrency =
            maxConcurrency ?? Platform.numberOfProcessors.clamp(1, 4);

  static final instance = IsolatePool();

  final int _maxConcurrency;
  int _running = 0;
  final List<Completer<void>> _waitQueue = [];

  /// 在受控并发下执行 Isolate 计算。
  ///
  /// 语义与 [Isolate.run] 相同，但同时运行的任务数不超过 [_maxConcurrency]。
  Future<T> run<T, U>(T Function(U message) computation, U message) async {
    await _acquire();
    try {
      return await Isolate.run(() => computation(message));
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_running < _maxConcurrency) {
      _running++;
      return;
    }
    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
  }

  void _release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeAt(0).complete();
    } else {
      _running--;
    }
  }
}
