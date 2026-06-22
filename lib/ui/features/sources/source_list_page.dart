import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/source_repository.dart';
import '../../../data/repositories/filesystem_repository.dart';
import '../../../domain/core/result.dart';
import '../../../domain/models/source.dart';
import '../../core/view_models/base_view_model.dart';
import 'view_models/source_list_view_model.dart';
import 'widgets/source_card.dart';
import 'widgets/smb_config_dialog.dart';

class SourceListPage extends StatelessWidget {
  const SourceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SourceListViewModel(
        sourceRepository: context.read<SourceRepository>(),
        resourceRepository: context.read<ResourceRepository>(),
        filesystemRepository: context.read<FilesystemRepository>(),
      )..loadSources(),
      child: const _SourceListView(),
    );
  }
}

class _SourceListView extends StatelessWidget {
  const _SourceListView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SourceListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('数据源')),
      body: _buildBody(context, vm),
      floatingActionButton: _buildFab(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, SourceListViewModel vm) {
    switch (vm.state) {
      case UiState.loading:
        return const Center(child: CircularProgressIndicator());
      case UiState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(vm.errorMessage ?? '加载失败'),
              if (vm.canRetry) ...[
                const SizedBox(height: 16),
                ElevatedButton(onPressed: vm.retry, child: const Text('重试')),
              ],
            ],
          ),
        );
      case UiState.idle:
      case UiState.success:
        if (vm.sources.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildList(context, vm);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('还没有数据源', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '点击 + 添加',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, SourceListViewModel vm) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vm.sources.length,
      itemBuilder: (context, index) {
        final source = vm.sources[index];
        final count = vm.resourceCounts[source.id] ?? 0;

        return SourceCard(
          source: source,
          resourceCount: count,
          onToggle: (_) => vm.toggleSource(source.id),
          onRename: () =>
              _showRenameDialog(context, vm, source.id, source.name),
          onDelete: () =>
              _showDeleteDialog(context, vm, source.id, source.name, count),
          onTap: () =>
              context.push('/sources/${source.id}/browser', extra: source.name),
          onEditSmbCredentials: source.type == SourceType.smb
              ? () => _showEditSmbCredentialsDialog(context, vm, source)
              : null,
        );
      },
    );
  }

  Widget _buildFab(BuildContext context, SourceListViewModel vm) {
    return FloatingActionButton(
      onPressed: () => _showAddMenu(context, vm),
      child: const Icon(Icons.add),
    );
  }

  void _showAddMenu(BuildContext context, SourceListViewModel vm) {
    final pageContext = context;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('添加本地文件夹'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickLocalFolder(pageContext, vm);
              },
            ),
            ListTile(
              leading: const Icon(Icons.computer),
              title: const Text('添加 SMB 网络共享'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showSmbConfigDialog(pageContext, vm);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 请求存储权限，返回是否已获得授权
  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // Android 11+ (API 30+): 需要 MANAGE_EXTERNAL_STORAGE
    if (await Permission.manageExternalStorage.isGranted) return true;

    // 先尝试普通存储权限（Android 10 及以下）
    final status = await Permission.storage.request();
    if (status.isGranted) return true;

    // Android 11+：引导用户到系统设置开启「所有文件访问」
    if (!context.mounted) return false;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要存储权限'),
        content: const Text('请在设置中开启「所有文件访问」权限，以便浏览本地文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('去设置'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await Permission.manageExternalStorage.request();
      return Permission.manageExternalStorage.isGranted;
    }
    return false;
  }

  Future<void> _pickLocalFolder(
    BuildContext context,
    SourceListViewModel vm,
  ) async {
    // 先请求存储权限
    final granted = await _requestStoragePermission(context);
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未授予存储权限，无法添加本地文件夹'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    if (!context.mounted) return;

    // 使用文件夹名作为默认源名称
    final normalizedPath = p.normalize(result);
    final name = p.basename(normalizedPath).isEmpty
        ? normalizedPath
        : p.basename(normalizedPath);

    final addResult = await vm.addLocalSource(
      name: name,
      rootPath: normalizedPath,
    );
    if (addResult is Err && context.mounted) {
      final error = (addResult as Err).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加失败: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已添加数据源：$name')));
    }
  }

  Future<void> _showSmbConfigDialog(
    BuildContext context,
    SourceListViewModel vm,
  ) async {
    final result = await SmbConfigDialog.show(
      context,
      onTestConnection: vm.testSmbConnection,
    );
    if (result == null || !context.mounted) return;

    // 构建 rootPath（UNC 格式）
    final rootPath = '\\\\${result.host}\\${result.share}';

    final addResult = await vm.addSmbSource(
      name: result.name,
      rootPath: rootPath,
      host: result.host,
      port: result.port,
      username: result.username,
      password: result.password,
      domain: result.domain,
    );

    if (addResult is Err && context.mounted) {
      final error = (addResult as Err).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加失败: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已添加 SMB 数据源：${result.name}')));
    }
  }

  void _showRenameDialog(
    BuildContext context,
    SourceListViewModel vm,
    String id,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '数据源名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == currentName) {
                Navigator.pop(context);
                return;
              }

              Navigator.pop(context);
              final result = await vm.renameSource(id, newName);
              if (result is Err && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('重命名失败: ${result.error.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    SourceListViewModel vm,
    String id,
    String name,
    int resourceCount,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除数据源'),
        content: Text(
          '确定要删除数据源“$name”吗？该源下的 $resourceCount 个资源将被移除，'
          '绑定的标签关联也会一并清除。标签本身会保留。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final result = await vm.deleteSource(id);
              if (result is Err && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('删除失败: ${result.error.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSmbCredentialsDialog(
    BuildContext context,
    SourceListViewModel vm,
    Source source,
  ) async {
    final result = await SmbConfigDialog.show(
      context,
      initialName: source.name,
      initialHost: source.host,
      initialShare: _extractShareFromRootPath(source.rootPath),
      initialPort: source.port ?? 445,
      initialUsername: source.username,
      initialDomain: source.domain,
      isEditMode: true,
      onTestConnection: vm.testSmbConnection,
    );

    if (result == null || !context.mounted) return;

    final updateResult = await vm.updateSmbCredentials(
      sourceId: source.id,
      username: result.username,
      password: result.password,
      domain: result.domain,
    );

    if (updateResult is Err && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新凭据失败: ${updateResult.error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SMB 凭据已更新')));
    }
  }

  String? _extractShareFromRootPath(String rootPath) {
    // 处理 \\host\share 格式
    if (rootPath.startsWith('\\\\')) {
      final parts = rootPath.substring(2).split('\\');
      if (parts.length >= 2) return parts[1];
    }
    return null;
  }
}
