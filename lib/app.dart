import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/database_service.dart';
import 'data/services/secure_storage_service.dart';
import 'data/services/thumbnail_cache_service.dart';
import 'data/repositories/source_repository.dart';
import 'data/repositories/resource_repository.dart';
import 'data/repositories/tag_repository.dart';
import 'data/repositories/filesystem_repository.dart';
import 'data/repositories/thumbnail_repository.dart';
import 'data/repositories/organization_repository.dart';
import 'shared/file_source/file_source_factory.dart';
import 'ui/core/router.dart';
import 'ui/core/theme/app_theme.dart';

class ResourceViewerApp extends StatelessWidget {
  const ResourceViewerApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // DatabaseService（单例，由 main.dart 注入）
        Provider<AppDatabase>.value(value: database),

        // Services
        Provider(create: (_) => SecureStorageService()),
        Provider(
          create: (ctx) {
            final factory = FileSourceFactory();
            final secureStorage = ctx.read<SecureStorageService>();
            // 注入密码提供函数
            factory.passwordProvider = secureStorage.getPassword;
            return factory;
          },
        ),
        Provider(create: (_) => ThumbnailCacheService()),

        // Repositories（依赖 DatabaseService）
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
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
