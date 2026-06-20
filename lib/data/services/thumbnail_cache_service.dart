import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 缩略图磁盘 LRU 缓存服务
///
/// 容量上限可配置，默认 500MB。
/// 写入时自动检查总大小，超限按 LRU 删除最旧文件。
class ThumbnailCacheService {
  ThumbnailCacheService({this._cacheDirectory});

  final String? _cacheDirectory;

  /// 默认容量上限（500MB）
  static const defaultCapacity = 500 * 1024 * 1024;

  /// 最小容量（500MB）
  static const minCapacity = 500 * 1024 * 1024;

  /// 当前容量上限
  int _capacity = defaultCapacity;

  /// 索引文件名
  static const _indexFileName = 'thumb_index.json';

  /// 获取缓存目录路径
  Future<String> get _thumbDir async {
    final cacheDirectory = _cacheDirectory;
    if (cacheDirectory != null) {
      return p.join(cacheDirectory, 'thumbs');
    }
    final cacheDir = await getApplicationCacheDirectory();
    return p.join(cacheDir.path, 'thumbs');
  }

  /// 获取索引文件路径
  Future<String> get _indexPath async {
    return p.join(await _thumbDir, _indexFileName);
  }

  /// 获取当前缓存大小（字节）
  Future<int> getSize() async {
    final dir = Directory(await _thumbDir);
    if (!await dir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }
    return totalSize;
  }

  /// 获取当前容量上限（字节）
  int getCapacity() => _capacity;

  /// 设置容量上限
  ///
  /// 最小容量 500MB，拒绝更小值。
  void setCapacity(int bytes) {
    if (bytes < minCapacity) {
      throw ArgumentError('容量不能小于 ${minCapacity ~/ (1024 * 1024)}MB');
    }
    _capacity = bytes;
  }

  /// 获取缩略图文件路径
  Future<String?> get(String resourceId) async {
    final thumbPath = p.join(await _thumbDir, 'thumb_$resourceId.jpg');
    final file = File(thumbPath);
    if (await file.exists()) {
      // 更新访问时间
      await _updateAccessTime(resourceId);
      return thumbPath;
    }
    return null;
  }

  /// 保存缩略图
  ///
  /// 写入后自动检查并淘汰最旧文件。
  Future<void> put(String resourceId, List<int> bytes) async {
    final dir = await _thumbDir;
    await Directory(dir).create(recursive: true);

    final thumbPath = p.join(dir, 'thumb_$resourceId.jpg');
    await File(thumbPath).writeAsBytes(bytes);

    // 更新索引
    await _updateAccessTime(resourceId);

    // 检查并淘汰
    await _evictIfNeeded();
  }

  /// 删除指定缩略图
  Future<void> delete(String resourceId) async {
    final thumbPath = p.join(await _thumbDir, 'thumb_$resourceId.jpg');
    final file = File(thumbPath);
    if (await file.exists()) {
      await file.delete();
    }
    await _removeFromIndex(resourceId);
  }

  /// 清理所有缓存
  Future<void> clearCache() async {
    final dir = Directory(await _thumbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// 更新访问时间索引
  Future<void> _updateAccessTime(String resourceId) async {
    final index = await _loadIndex();
    index[resourceId] = DateTime.now().toIso8601String();
    await _saveIndex(index);
  }

  /// 从索引中移除
  Future<void> _removeFromIndex(String resourceId) async {
    final index = await _loadIndex();
    index.remove(resourceId);
    await _saveIndex(index);
  }

  /// 检查并淘汰超限文件
  Future<void> _evictIfNeeded() async {
    final currentSize = await getSize();
    if (currentSize <= _capacity) return;

    final index = await _loadIndex();
    final dir = await _thumbDir;

    // 按访问时间排序（最旧的在前）
    final sortedEntries = index.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    int evictedSize = 0;
    final targetEvict = currentSize - _capacity;

    for (final entry in sortedEntries) {
      if (evictedSize >= targetEvict) break;

      final thumbPath = p.join(dir, 'thumb_${entry.key}.jpg');
      final file = File(thumbPath);
      if (await file.exists()) {
        final stat = await file.stat();
        await file.delete();
        evictedSize += stat.size;
        index.remove(entry.key);
      }
    }

    await _saveIndex(index);
  }

  /// 加载索引
  Future<Map<String, String>> _loadIndex() async {
    final indexPath = await _indexPath;
    final file = File(indexPath);
    if (!await file.exists()) return {};

    try {
      final content = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(content);
      return json.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      return {};
    }
  }

  /// 保存索引
  Future<void> _saveIndex(Map<String, String> index) async {
    final indexPath = await _indexPath;
    final dir = Directory(p.dirname(indexPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await File(indexPath).writeAsString(jsonEncode(index));
  }
}
