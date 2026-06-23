import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../data/services/thumbnail_cache_service.dart';
import '../../../domain/models/app_config.dart';
import '../../core/view_models/base_view_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'view_models/settings_view_model.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_select_row.dart';
import 'widgets/settings_switch_row.dart';
import 'widgets/about_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel(
      settingsRepository: context.read<SettingsRepository>(),
      thumbnailCacheService: context.read<ThumbnailCacheService>(),
    );
    _viewModel.addListener(_onChanged);
    _viewModel.loadConfig();
    _viewModel.startWatching();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    // 设置项更新失败时以 snackbar 提示，不覆盖整页状态
    final error = _viewModel.updateError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '重试',
            onPressed: () => _viewModel.retry(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_viewModel.state) {
      case UiState.idle:
      case UiState.loading:
        return const Center(child: CircularProgressIndicator());
      case UiState.error:
        return _buildErrorView();
      case UiState.success:
        return _buildContent();
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _viewModel.errorMessage ?? '加载设置失败',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          if (_viewModel.canRetry) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: _viewModel.retry, child: const Text('重试')),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    final config = _viewModel.config;
    if (config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildCacheSection(config),
        _buildAppearanceSection(config),
        _buildViewerSection(config),
        _buildAboutSection(),
        _buildRestoreDefaultsButton(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ============================================================================
  // 缓存管理
  // ============================================================================

  Widget _buildCacheSection(AppConfig config) {
    final cacheLimitMB = config.cacheLimitMB;
    final cacheUsedMB = (_viewModel.cacheSizeBytes / (1024 * 1024)).round();
    final fillRatio = cacheLimitMB > 0
        ? (cacheUsedMB / cacheLimitMB).clamp(0.0, 1.0)
        : 0.0;

    final capacityOptions = const [500, 1000, 1500, 2000];

    return SettingsSection(
      title: '缓存管理',
      headerWidget: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('缩略图缓存', style: TextStyle(fontSize: 12)),
                    Text(
                      '已用: $cacheUsedMB MB / 上限: $cacheLimitMB MB',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillRatio,
                    minHeight: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '容量上限',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ...capacityOptions.map(
                      (mb) => _buildCapacityChip(
                        mb,
                        isSelected: config.cacheLimitMB == mb,
                      ),
                    ),
                    _buildCustomCapacityChip(config),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
      children: [
        _buildConcurrencySelector(config),
        _buildDangerButton(
          '清理缩略图缓存',
          isLoading: _viewModel.isClearingCache,
          onTap: () => _confirmClearCache(),
        ),
        if (_viewModel.cacheDirectory != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Text(
              '缓存位置: ${_viewModel.cacheDirectory}',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildCapacityChip(int mb, {required bool isSelected}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _viewModel.setCacheLimitMB(mb),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : colorScheme.outline,
          ),
        ),
        child: Text(
          '$mb MB',
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCapacityChip(AppConfig config) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPreset = const {
      500,
      1000,
      1500,
      2000,
    }.contains(config.cacheLimitMB);

    if (isPreset) {
      return GestureDetector(
        onTap: () => _showCustomCapacityDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Text(
            '自定义',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showCustomCapacityDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          '${config.cacheLimitMB} MB',
          style: const TextStyle(fontSize: 12, color: AppColors.primary),
        ),
      ),
    );
  }

  void _showCustomCapacityDialog() {
    final controller = TextEditingController(
      text: _viewModel.config?.cacheLimitMB.toString() ?? '500',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('自定义缓存容量'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '容量 (MB)',
            hintText: '最小 500 MB',
            suffixText: 'MB',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 500) {
                _viewModel.setCacheLimitMB(value);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入不小于 500 的整数')));
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清理缩略图缓存'),
        content: const Text('确定要清理所有缩略图缓存吗？此操作不会删除资源记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _viewModel.clearCache();
            },
            child: const Text('清理'),
          ),
        ],
      ),
    );
  }

  Widget _buildConcurrencySelector(AppConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '缩略图并发加载',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List.generate(8, (i) {
              final n = i + 1;
              final isSelected = config.thumbnailConcurrency == n;
              return GestureDetector(
                onTap: () => _viewModel.setThumbnailConcurrency(n),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton(
    String label, {
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isLoading ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      ),
    );
  }

  // ============================================================================
  // 外观
  // ============================================================================

  Widget _buildAppearanceSection(AppConfig config) {
    const themeOptions = [
      (mode: AppThemeMode.system, label: '跟随系统'),
      (mode: AppThemeMode.dark, label: '深色'),
      (mode: AppThemeMode.light, label: '浅色'),
    ];

    return SettingsSection(
      title: '外观',
      children: [
        SettingsSelectRow(
          label: '深色模式',
          selectedLabel: themeOptions
              .firstWhere((option) => option.mode == config.themeMode)
              .label,
          options: themeOptions.map((option) => option.label).toList(),
          onSelected: (index) {
            _viewModel.setThemeMode(themeOptions[index].mode);
          },
        ),
      ],
    );
  }

  // ============================================================================
  // 查看器默认设置
  // ============================================================================

  Widget _buildViewerSection(AppConfig config) {
    final pageDirections = ['左滑下一页（右→左）', '右滑下一页（左→右）'];
    final doublePageModes = ['自动', '始终单页', '始终双页'];

    return SettingsSection(
      title: '查看器默认设置',
      children: [
        SettingsSelectRow(
          label: '默认翻页方向',
          subtitle: '日漫默认为右向左阅读',
          selectedLabel: config.pageDirection == PageDirection.rightToLeft
              ? pageDirections[0]
              : pageDirections[1],
          options: pageDirections,
          onSelected: (index) {
            final direction = index == 0
                ? PageDirection.rightToLeft
                : PageDirection.leftToRight;
            _viewModel.setPageDirection(direction);
          },
        ),
        SettingsSelectRow(
          label: '双页显示',
          subtitle: '宽度≥900dp时自动双页',
          selectedLabel: doublePageModes[config.doublePageMode.index],
          options: doublePageModes,
          onSelected: (index) {
            final mode = DoublePageMode.values[index];
            _viewModel.setDoublePageMode(mode);
          },
        ),
        SettingsSwitchRow(
          label: '跨章节连续阅读',
          subtitle: '末页继续滑动切换下一章',
          value: config.crossChapter,
          onChanged: (value) => _viewModel.setCrossChapter(value),
        ),
      ],
    );
  }

  // ============================================================================
  // 关于
  // ============================================================================

  Widget _buildAboutSection() {
    return SettingsSection(title: '关于', children: [const AboutSection()]);
  }

  // ============================================================================
  // 恢复默认设置
  // ============================================================================

  Widget _buildRestoreDefaultsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _confirmResetDefaults(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          child: const Text('恢复默认设置'),
        ),
      ),
    );
  }

  void _confirmResetDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认设置'),
        content: const Text('确定要恢复所有设置为默认值吗？\n此操作不会清理缩略图缓存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _viewModel.resetDefaults();
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }
}
