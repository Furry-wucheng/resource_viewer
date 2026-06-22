import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/ui/features/sources/widgets/smb_config_dialog.dart';

void main() {
  testWidgets('修改已测试配置后重新禁用添加按钮', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var testCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmbConfigDialog(
            onTestConnection:
                ({
                  required host,
                  required share,
                  port = 445,
                  username,
                  password,
                  domain,
                }) async {
                  testCalls++;
                  return const Ok(true);
                },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, '源名称 *'),
      '家庭 NAS',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'SMB 地址 *'),
      'nas.local',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '共享名称 *'),
      'Media',
    );
    final testButton = find.widgetWithText(OutlinedButton, '测试连接');
    await tester.ensureVisible(testButton);
    await tester.tap(testButton);
    await tester.pump();

    expect(testCalls, 1);
    expect(find.text('连接成功'), findsOneWidget);
    FilledButton addButton = tester.widget(
      find.widgetWithText(FilledButton, '添加'),
    );
    expect(addButton.onPressed, isNotNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'SMB 地址 *'),
      'other.local',
    );
    await tester.pump();

    expect(find.text('连接成功'), findsNothing);
    addButton = tester.widget(find.widgetWithText(FilledButton, '添加'));
    expect(addButton.onPressed, isNull);
  });

  testWidgets('编辑凭据时服务器字段只读且新密码必填', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmbConfigDialog(
            isEditMode: true,
            initialHost: 'nas.local',
            initialShare: 'Media',
            onTestConnection:
                ({
                  required host,
                  required share,
                  port = 445,
                  username,
                  password,
                  domain,
                }) async => const Ok(true),
          ),
        ),
      ),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.elementAt(0).readOnly, isTrue);
    expect(fields.elementAt(1).readOnly, isTrue);
    expect(fields.elementAt(2).readOnly, isTrue);

    final testButton = find.widgetWithText(OutlinedButton, '测试连接');
    await tester.ensureVisible(testButton);
    await tester.tap(testButton);
    await tester.pump();
    expect(find.text('请输入新密码'), findsOneWidget);
  });
}
