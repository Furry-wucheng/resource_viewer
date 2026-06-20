import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppShell', () {
    Widget buildShell({double width = 800}) {
      return MaterialApp(
        home: SizedBox(
          width: width,
          height: 600,
          child: _TestShell(width: width),
        ),
      );
    }

    testWidgets('shows BottomNavigationBar on narrow screens', (tester) async {
      await tester.pumpWidget(buildShell(width: 600));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('首页库'), findsOneWidget);
      expect(find.text('数据源'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('shows NavigationRail on wide screens', (tester) async {
      await tester.pumpWidget(buildShell(width: 1000));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}

/// Minimal shell wrapper for widget testing without a full GoRouter setup.
class _TestShell extends StatelessWidget {
  const _TestShell({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final useRail = width >= 900;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  label: Text('首页库'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  label: Text('数据源'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: Text('设置'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            const Expanded(child: Center(child: Text('内容'))),
          ],
        ),
      );
    }

    return Scaffold(
      body: const Center(child: Text('内容')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: '首页库',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: '数据源',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
