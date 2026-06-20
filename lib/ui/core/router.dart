import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_page.dart';
import '../features/settings/settings_page.dart';
import '../features/sources/file_browser_page.dart';
import '../features/sources/source_list_page.dart';
import '../features/viewer/resource_viewer_page.dart';
import '../features/viewer/file_viewer_page.dart';
import 'widgets/app_shell.dart';

/// Root navigator key for full-screen routes that overlay the tab bar.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell navigator keys for each tab branch.
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _sourcesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'sources');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        // Branch 1: Sources
        StatefulShellBranch(
          navigatorKey: _sourcesNavigatorKey,
          routes: [
            GoRoute(
              path: '/sources',
              builder: (context, state) => const SourceListPage(),
              routes: [
                GoRoute(
                  path: ':id/browser',
                  parentNavigatorKey: _sourcesNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    // 源名称通过 extra 传递，如果没有则使用 ID
                    final sourceName = state.extra as String? ?? id;
                    return FileBrowserPage(
                      sourceId: id,
                      sourceName: sourceName,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 2: Settings
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    // Full-screen routes (overlay tab bar)
    GoRoute(
      path: '/viewer/:resourceId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final resourceId = state.pathParameters['resourceId']!;
        return ResourceViewerPage(resourceId: resourceId);
      },
    ),
    GoRoute(
      path: '/viewer/file/:sourceId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sourceId = state.pathParameters['sourceId']!;
        final request = state.extra! as FileViewerRequest;
        return FileViewerPage(
          sourceId: sourceId,
          entry: request.entry,
          sourceName: request.sourceName,
        );
      },
    ),
    GoRoute(
      path: '/tags/manager',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const _PlaceholderPage(title: '标签管理');
      },
    ),
  ],
);

// Placeholder pages for routes that don't have real pages yet.

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
