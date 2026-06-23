import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/settings_repository.dart';
import '../../../../data/services/thumbnail_cache_service.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/models/app_config.dart';
import '../../../core/view_models/base_view_model.dart';

/// 设置页状态与操作
class SettingsViewModel extends BaseViewModel {
  SettingsViewModel({
    required this._settingsRepository,
    required this._thumbnailCacheService,
    this.cacheSizeRefreshDebounce = const Duration(milliseconds: 500),
  });

  final SettingsRepository _settingsRepository;
  final ThumbnailCacheService _thumbnailCacheService;
  final Duration cacheSizeRefreshDebounce;

  // ---- 配置数据 ----
  AppConfig? _config;
  AppConfig? get config => _config;

  // ---- 缓存信息 ----
  int _cacheSizeBytes = 0;
  int get cacheSizeBytes => _cacheSizeBytes;
  int _cacheCapacityBytes = ThumbnailCacheService.defaultCapacity;
  int get cacheCapacityBytes => _cacheCapacityBytes;
  String? _cacheDirectory;
  String? get cacheDirectory => _cacheDirectory;
  bool _isClearingCache = false;
  bool get isClearingCache => _isClearingCache;

  // ---- 订阅 ----
  StreamSubscription<Result<AppConfig>>? _configSubscription;

  // ---- 初始化 ----

  /// 加载配置与缓存状态
  Future<void> loadConfig() async {
    startLoading();
    final result = await _settingsRepository.getConfig();
    _applyConfigResult(result);
    if (state == UiState.success) {
      await _refreshCacheInfo();
    }
  }

  /// 开始监听配置变化
  void startWatching() {
    _configSubscription?.cancel();
    _configSubscription = _settingsRepository.watchConfig().listen((result) {
      _applyConfigResult(result);
    });
  }

  void _applyConfigResult(Result<AppConfig> result) {
    switch (result) {
      case Ok(:final value):
        _config = value;
        _cacheCapacityBytes = value.cacheLimitMB * 1024 * 1024;
        // 同步到缓存服务
        if (_cacheCapacityBytes >= ThumbnailCacheService.minCapacity) {
          _thumbnailCacheService.setCapacity(_cacheCapacityBytes);
        }
      case Err():
        break; // setResult will handle state
    }
    setResult(result);
  }

  /// 刷新缓存信息（大小、目录）
  Future<void> _refreshCacheInfo() async {
    try {
      _cacheSizeBytes = await _thumbnailCacheService.getSize();
      _cacheCapacityBytes = _thumbnailCacheService.getCapacity();
      _cacheDirectory = await _thumbnailCacheService.getCacheDirectory();
    } on FileSystemException {
      // 缓存目录暂不可读，不阻塞设置页
      _cacheSizeBytes = 0;
    } catch (e) {
      // 非预期的异常仍需记录，便于排查
      debugPrint('SettingsViewModel: 读取缓存信息失败 — $e');
      _cacheSizeBytes = 0;
    }
    notifyListeners();
  }

  // ---- 操作错误（仅影响最近一次更新，不切换整页状态） ----

  String? _updateError;
  String? get updateError => _updateError;

  void _setUpdateResult(Result<AppConfig> result) {
    switch (result) {
      case Ok(:final value):
        _config = value;
        _updateError = null;
        notifyListeners();
      case Err(:final error):
        // 保留现有 config 不变，只记录错误供 UI 以 snackbar 提示
        _updateError = error.message;
        notifyListeners();
    }
  }

  // ---- 主题设置 ----

  Future<void> setThemeMode(AppThemeMode mode) async {
    final result = await _settingsRepository.updateThemeMode(mode);
    _setUpdateResult(result);
  }

  // ---- 查看器默认值 ----

  Future<void> setPageDirection(PageDirection direction) async {
    final result = await _settingsRepository.updatePageDirection(direction);
    _setUpdateResult(result);
  }

  Future<void> setDoublePageMode(DoublePageMode mode) async {
    final result = await _settingsRepository.updateDoublePageMode(mode);
    _setUpdateResult(result);
  }

  Future<void> setCrossChapter(bool enabled) async {
    final result = await _settingsRepository.updateCrossChapter(enabled);
    _setUpdateResult(result);
  }

  // ---- 缓存管理 ----

  Future<void> setCacheLimitMB(int limitMB) async {
    final result = await _settingsRepository.updateCacheLimitMB(limitMB);
    if (result is Ok<AppConfig>) {
      _cacheCapacityBytes = limitMB * 1024 * 1024;
      if (_cacheCapacityBytes >= ThumbnailCacheService.minCapacity) {
        _thumbnailCacheService.setCapacity(_cacheCapacityBytes);
      }
    }
    _setUpdateResult(result);
  }

  /// 缩略图加载并发数
  Future<void> setThumbnailConcurrency(int n) async {
    final clamped = n.clamp(1, 8);
    final result = await _settingsRepository.updateThumbnailConcurrency(clamped);
    _setUpdateResult(result);
  }

  Future<void> clearCache() async {
    _isClearingCache = true;
    notifyListeners();
    try {
      await _thumbnailCacheService.clearCache();
      _cacheSizeBytes = 0;
    } catch (_) {
      // 清理失败，下次重试
    } finally {
      _isClearingCache = false;
      await _refreshCacheInfo();
    }
  }

  /// 刷新缓存大小（用于清理后）
  Future<void> refreshCacheSize() => _refreshCacheInfo();

  // ---- 恢复默认 ----

  Future<void> resetDefaults() async {
    final result = await _settingsRepository.resetDefaults();
    setResult(result);
    if (result is Ok<AppConfig>) {
      _config = result.value;
      _cacheCapacityBytes = _config!.cacheLimitMB * 1024 * 1024;
      if (_cacheCapacityBytes >= ThumbnailCacheService.minCapacity) {
        _thumbnailCacheService.setCapacity(_cacheCapacityBytes);
      }
    }
  }

  // ---- 生命周期 ----

  @override
  Future<void> retry() => loadConfig();

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }
}
