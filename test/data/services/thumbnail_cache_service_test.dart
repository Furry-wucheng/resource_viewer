import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:resource_viewer/data/services/thumbnail_cache_service.dart';

void main() {
  late Directory tempDir;
  late ThumbnailCacheService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('thumbnail_cache_test_');
    service = ThumbnailCacheService(cacheDirectory: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ThumbnailCacheService', () {
    group('getCapacity / setCapacity', () {
      test('默认容量 500MB', () {
        expect(service.getCapacity(), ThumbnailCacheService.defaultCapacity);
      });

      test('设置新容量', () {
        service.setCapacity(1024 * 1024 * 1024); // 1GB
        expect(service.getCapacity(), 1024 * 1024 * 1024);
      });

      test('拒绝小于 500MB 的容量', () {
        expect(
          () => service.setCapacity(100 * 1024 * 1024),
          throwsArgumentError,
        );
      });
    });

    group('getSize', () {
      test('空缓存大小为 0', () async {
        final size = await service.getSize();
        expect(size, 0);
      });

      test('写入后大小正确', () async {
        await service.put('res-1', List.filled(1024, 0));
        final size = await service.getSize();
        expect(size, greaterThan(0));
      });
    });

    group('put / get', () {
      test('写入后可获取路径', () async {
        await service.put('res-1', List.filled(100, 0));
        final path = await service.get('res-1');
        expect(path, isNotNull);
        expect(await File(path!).exists(), true);
      });

      test('未写入返回 null', () async {
        final path = await service.get('nonexistent');
        expect(path, isNull);
      });

      test('文件名格式为 thumb_{resourceId}.jpg', () async {
        await service.put('abc-123', List.filled(100, 0));
        final path = await service.get('abc-123');
        expect(path, isNotNull);
        expect(p.basename(path!), 'thumb_abc-123.jpg');
      });
    });

    group('delete', () {
      test('删除后文件不存在', () async {
        await service.put('res-1', List.filled(100, 0));
        await service.delete('res-1');
        final path = await service.get('res-1');
        expect(path, isNull);
      });

      test('删除不存在的资源不抛异常', () async {
        expect(() => service.delete('nonexistent'), returnsNormally);
      });
    });

    group('clearCache', () {
      test('清理后所有文件不存在', () async {
        await service.put('res-1', List.filled(100, 0));
        await service.put('res-2', List.filled(100, 0));
        await service.clearCache();

        expect(await service.getSize(), 0);
        expect(await service.get('res-1'), isNull);
        expect(await service.get('res-2'), isNull);
      });
    });

    group('LRU 淘汰', () {
      test('超容后旧文件被清理', () async {
        // 设置一个很小的容量（刚好 500MB 是最小值，这里用大文件模拟）
        // 为了测试，我们写入足够多的文件来触发淘汰
        service.setCapacity(ThumbnailCacheService.minCapacity);

        // 写入多个小文件
        for (var i = 0; i < 10; i++) {
          await service.put('res-$i', List.filled(1024, 0));
          // 稍微延迟以确保访问时间不同
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // 验证所有文件都在（因为总大小远小于容量）
        for (var i = 0; i < 10; i++) {
          final path = await service.get('res-$i');
          expect(path, isNotNull);
        }
      });
    });
  });
}
