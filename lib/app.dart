import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/database_service.dart';
import 'data/services/secure_storage_service.dart';
import 'data/services/thumbnail_cache_service.dart';
import 'data/services/video_stream_service.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/source_repository.dart';
import 'data/repositories/resource_repository.dart';
import 'data/repositories/tag_repository.dart';
import 'data/repositories/filesystem_repository.dart';
import 'data/repositories/thumbnail_repository.dart';
import 'data/repositories/organization_repository.dart';
import 'domain/core/result.dart';
import 'domain/models/app_config.dart' as domain;
import 'shared/file_source/file_source_factory.dart';
import 'ui/core/router.dart';
import 'ui/core/theme/app_theme.dart';

class ResourceViewerApp extends StatefulWidget {
  const ResourceViewerApp({super.key, required this.database});

  final AppDatabase database;

  @override
  State<ResourceViewerApp> createState() => _ResourceViewerAppState();
}

class _ResourceViewerAppState extends State<ResourceViewerApp>
    with WidgetsBindingObserver {
  late final SettingsRepository _settingsRepository;
  StreamSubscription<Result<domain.AppConfig>>? _configSubscription;

  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configureImageCache();
    _settingsRepository = SettingsRepository(widget.database);
    _loadInitialTheme();
    _listenToConfigChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _configSubscription?.cancel();
    super.dispose();
  }

  void _configureImageCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = 200;
    cache.maximumSizeBytes = 200 << 20; // 200 MB
  }

  @override
  void didHaveMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      PaintingBinding.instance.imageCache.clear();
    }
  }

  Future<void> _loadInitialTheme() async {
    final result = await _settingsRepository.getConfig();
    if (result case Ok(value: final config)) {
      if (mounted) {
        setState(() {
          _themeMode = _toThemeMode(config.themeMode);
        });
      }
    }
  }

  void _listenToConfigChanges() {
    _configSubscription = _settingsRepository.watchConfig().listen((result) {
      if (result case Ok(value: final config)) {
        if (mounted) {
          setState(() {
            _themeMode = _toThemeMode(config.themeMode);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.database),
        // Services
        Provider(create: (_) => SecureStorageService()),
        Provider(
          create: (ctx) {
            final factory = FileSourceFactory();
            final secureStorage = ctx.read<SecureStorageService>();
            factory.passwordProvider = secureStorage.getPassword;
            return factory;
          },
        ),
        Provider(create: (_) => ThumbnailCacheService()),
        Provider(
          create: (_) => VideoStreamService(),
          dispose: (_, service) => unawaited(service.dispose()),
        ),

        // Repositories（依赖 DatabaseService）
        Provider<SettingsRepository>.value(value: _settingsRepository),
        Provider(
          create: (ctx) => FilesystemRepository(
            ctx.read<AppDatabase>(),
            ctx.read<FileSourceFactory>(),
            secureStorageService: ctx.read<SecureStorageService>(),
          ),
        ),
        Provider(
          create: (ctx) => SourceRepository(
            ctx.read<AppDatabase>(),
            fileSourceFactory: ctx.read<FileSourceFactory>(),
            thumbnailCacheService: ctx.read<ThumbnailCacheService>(),
            secureStorageService: ctx.read<SecureStorageService>(),
            filesystemRepository: ctx.read<FilesystemRepository>(),
          ),
        ),
        Provider(create: (ctx) => ResourceRepository(ctx.read<AppDatabase>())),
        Provider(create: (ctx) => TagRepository(ctx.read<AppDatabase>())),
        Provider(create: (_) => OrganizationRepository()),
        Provider(
          create: (ctx) =>
              ThumbnailRepository(ctx.read<ThumbnailCacheService>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Resource Viewer',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        routerConfig: router,
      ),
    );
  }

  ThemeMode _toThemeMode(domain.AppThemeMode mode) => switch (mode) {
    domain.AppThemeMode.system => ThemeMode.system,
    domain.AppThemeMode.light => ThemeMode.light,
    domain.AppThemeMode.dark => ThemeMode.dark,
  };
}
