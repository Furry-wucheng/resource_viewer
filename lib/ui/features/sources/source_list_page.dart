import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../../data/repositories/resource_repository.dart';
import '../../../data/repositories/source_repository.dart';
import '../../../domain/core/result.dart';
import '../../core/view_models/base_view_model.dart';
import 'view_models/source_list_view_model.dart';
import 'widgets/source_card.dart';

class SourceListPage extends StatelessWidget {
  const SourceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SourceListViewModel(
        sourceRepository: context.read<SourceRepository>(),
        resourceRepository: context.read<ResourceRepository>(),
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
                ElevatedButton(
                  onPressed: vm.retry,
                  child: const Text('重试'),
                ),
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
          Text(
            '还没有数据源',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
          onRename: () => _showRenameDialog(context, vm, source.id, source.name),
          onDelete: () => _showDeleteDialog(context, vm, source.id, source.name),
          onTap: () => context.push('/sources/${source.id}/browser', extra: source.name),
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
              subtitle: const Text('即将推出'),
              enabled: false,
              onTap: () {
                Navigator.pop(sheetContext);
                // TODO: 实现 SMB 源添加
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocalFolder(
    BuildContext context,
    SourceListViewModel vm,
  ) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加数据源：$name')),
      );
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
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除数据源'),
        content: Text('确定删除"$name"？\n\n删除后将同时移除该源下的所有资源和缩略图，此操作不可撤销。'),
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
}
