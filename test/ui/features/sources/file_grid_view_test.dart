import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/ui/features/sources/widgets/file_grid_view.dart';

void main() {
  testWidgets('网格使用预览加载器显示图片而不是文件图标', (tester) async {
    const entry = FileEntry(
      name: 'cover.jpg',
      path: 'album/cover.jpg',
      isDirectory: false,
    );
    var calls = 0;
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
      'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileGridView(
            entries: const [entry],
            thumbnailLoader: (_) async {
              calls++;
              return bytes;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('file-thumbnail-album/cover.jpg')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.image), findsNothing);
    expect(calls, 1);
  });

  testWidgets('文件夹条目右下角显示小文件夹标识', (tester) async {
    const entry = FileEntry(
      name: 'my_folder',
      path: 'my_folder',
      isDirectory: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FileGridView(entries: [entry]),
        ),
      ),
    );

    // 文件夹图标应出现两次：一次是主图标（48px），一次是右下角标识（14px）
    expect(find.byIcon(Icons.folder), findsNWidgets(2));
  });

  testWidgets('文件条目不显示右下角文件夹标识', (tester) async {
    const entry = FileEntry(
      name: 'photo.jpg',
      path: 'photo.jpg',
      isDirectory: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FileGridView(entries: [entry]),
        ),
      ),
    );

    // 文件条目只有一个图片图标，没有文件夹标识
    expect(find.byIcon(Icons.folder), findsNothing);
    expect(find.byIcon(Icons.image), findsOneWidget);
  });
}
