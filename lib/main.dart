import 'package:flutter/material.dart';

import 'app.dart';
import 'data/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final db = AppDatabase();
    // drift 构造是 lazy 的，需显式预热连接以触发实际打开/迁移，
    // 否则初始化错误会在首次查询时抛出（已在 runApp 内部，无法兜住）
    await db.customSelect('SELECT 1').get();
    runApp(ResourceViewerApp(database: db));
  } catch (e) {
    // Fatal 错误：数据库损坏等，显示全屏阻塞页
    runApp(FatalErrorApp(error: e));
  }
}

/// Fatal 错误全屏阻塞页
class FatalErrorApp extends StatelessWidget {
  const FatalErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resource Viewer - Error',
      theme: ThemeData.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  '数据库异常，请重启应用',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '错误详情: $error',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
