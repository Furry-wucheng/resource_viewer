import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resource_viewer/data/repositories/filesystem_repository.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/ui/features/sources/widgets/directory_tree.dart';

class _MockFilesystemRepository extends Mock
    implements FilesystemRepository {}

void main() {
  testWidgets('大量根目录可滚动且不会 RenderFlex overflow', (tester) async {
    final repository = _MockFilesystemRepository();
    final entries = List.generate(
      300,
      (index) => FileEntry(
        name: 'folder-$index',
        path: 'folder-$index',
        isDirectory: true,
      ),
    );
    when(() => repository.listDirectory('source', ''))
        .thenAnswer((_) async => Ok(entries));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 600,
            child: DirectoryTree(
              sourceId: 'source',
              sourceName: '测试源',
              filesystemRepository: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1000),
    );
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
