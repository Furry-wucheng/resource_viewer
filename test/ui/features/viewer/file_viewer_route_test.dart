import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:resource_viewer/data/repositories/settings_repository.dart';
import 'package:resource_viewer/data/repositories/source_repository.dart';
import 'package:resource_viewer/data/repositories/filesystem_repository.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/app_config.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/domain/models/source.dart';
import 'package:resource_viewer/shared/file_source/file_source.dart';
import 'package:resource_viewer/shared/file_source/file_source_factory.dart';
import 'package:resource_viewer/ui/features/viewer/file_viewer_page.dart';
import 'package:resource_viewer/ui/features/viewer/file_sequence_viewer_page.dart';

class _MockSourceRepository extends Mock implements SourceRepository {}

class _MockFileSourceFactory extends Mock implements FileSourceFactory {}

class _MockFilesystemRepository extends Mock implements FilesystemRepository {}

class _MockFileSource extends Mock implements FileSource {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _RouteObserver extends NavigatorObserver {
  int pushes = 0;
  int replacements = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacements++;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

void main() {
  testWidgets('文件加载完成只更新当前路由，不再 pushReplacement', (tester) async {
    final sourceRepository = _MockSourceRepository();
    final fileSourceFactory = _MockFileSourceFactory();
    final filesystemRepository = _MockFilesystemRepository();
    final fileSource = _MockFileSource();
    final settingsRepo = _MockSettingsRepository();
    final observer = _RouteObserver();
    final now = DateTime(2026);
    final source = Source(
      id: 'source',
      name: '本地源',
      type: SourceType.local,
      rootPath: r'D:\Pictures',
      enabled: true,
      isAvailable: true,
      createdAt: now,
      updatedAt: now,
    );
    final entry = FileEntry(
      name: '1.jpg',
      path: 'album/1.jpg',
      isDirectory: false,
    );
    when(
      () => sourceRepository.getSourceById('source'),
    ).thenAnswer((_) async => Ok(source));
    when(
      () => fileSourceFactory.createAsync(source),
    ).thenAnswer((_) async => fileSource);
    when(
      () => filesystemRepository.listDirectory('source', 'album'),
    ).thenAnswer(
      (_) async => Ok([
        entry,
        const FileEntry(name: '2.jpg', path: 'album/2.jpg', isDirectory: false),
      ]),
    );
    when(() => fileSource.readFile(any())).thenAnswer(
      (_) async => base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
        'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    when(() => settingsRepo.getConfig()).thenAnswer(
      (_) async => Ok(
        AppConfig(
          id: 1,
          themeMode: AppThemeMode.system,
          pageDirection: PageDirection.rightToLeft,
          doublePageMode: DoublePageMode.auto,
          crossChapter: true,
          cacheLimitMB: 500,
          autoSyncInterval: AutoSyncInterval.off,
          updatedAt: now,
        ),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SourceRepository>.value(value: sourceRepository),
          Provider<FileSourceFactory>.value(value: fileSourceFactory),
          Provider<FilesystemRepository>.value(value: filesystemRepository),
          Provider<SettingsRepository>.value(value: settingsRepo),
        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => FileViewerPage(
                      sourceId: 'source',
                      entry: entry,
                      sourceName: '本地源',
                    ),
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    final initialPushes = observer.pushes;

    await tester.tap(find.text('打开'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(FileSequenceViewerPage), findsOneWidget);
    expect(observer.pushes - initialPushes, 1);
    expect(observer.replacements, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('viewer-page-view')),
      const Offset(-500, 0),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();

    final viewerCenter = tester.getCenter(
      find.byKey(const ValueKey('viewer-page-view')),
    );
    await tester.tapAt(viewerCenter);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    await tester.tapAt(viewerCenter);
    await tester.pump(const Duration(milliseconds: 350));
    verify(() => fileSource.readFile('album/1.jpg')).called(1);
    verify(() => fileSource.readFile('album/2.jpg')).called(1);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('打开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
