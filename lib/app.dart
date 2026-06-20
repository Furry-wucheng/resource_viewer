import 'package:flutter/material.dart';

import 'ui/core/router.dart';
import 'ui/core/theme/app_theme.dart';

class ResourceViewerApp extends StatelessWidget {
  const ResourceViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider will wrap this in phase 02 when Services/Repositories are created:
    //   MultiProvider(providers: [...], child: MaterialApp.router(...))
    return MaterialApp.router(
      title: 'Resource Viewer',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
