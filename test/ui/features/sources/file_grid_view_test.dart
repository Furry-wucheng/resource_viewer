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
}
