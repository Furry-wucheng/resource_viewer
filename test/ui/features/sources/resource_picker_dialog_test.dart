import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/ui/features/sources/widgets/resource_picker_dialog.dart';

import '../../../helpers/mock_factories.dart';

void main() {
  testWidgets('select all children selects one level only', (tester) async {
    final source = MockFileSource();
    when(() => source.listDirectory('root')).thenAnswer(
      (_) async => const [
        FileEntry(name: 'parent', path: 'root/parent', isDirectory: true),
      ],
    );
    when(() => source.listDirectory('root/parent')).thenAnswer(
      (_) async => const [
        FileEntry(name: 'child', path: 'root/parent/child', isDirectory: true),
      ],
    );
    when(() => source.listDirectory('root/parent/child')).thenAnswer(
      (_) async => const [
        FileEntry(
          name: 'grand',
          path: 'root/parent/child/grand',
          isDirectory: true,
        ),
      ],
    );
    when(() => source.listDirectory('root/parent/child/grand')).thenAnswer(
      (_) async => const [
        FileEntry(
          name: '1.jpg',
          path: 'root/parent/child/grand/1.jpg',
          isDirectory: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResourcePickerDialog(
          title: 'Pick',
          fileSource: source,
          rootPath: 'root',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('parent'));
    await tester.pump();
    await tester.tap(find.text('全选子项'));
    await tester.pump();

    expect(find.text('已选 1 项'), findsOneWidget);
  });
}
