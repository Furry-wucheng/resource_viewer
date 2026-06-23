import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/ui/features/viewer/widgets/org_mode_switcher.dart';

void main() {
  testWidgets('chapter option is disabled without subfolders', (tester) async {
    OrganizationMode? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrgModeSwitcher(
            currentMode: OrganizationMode.flatgrid,
            chapterEnabled: false,
            onModeChanged: (mode) => selected = mode,
          ),
        ),
      ),
    );

    await tester.tap(find.text('章节'));
    await tester.pump();
    expect(selected, isNull);

    await tester.tap(find.text('画廊'));
    await tester.pump();
    expect(selected, OrganizationMode.gallery);
  });
}
