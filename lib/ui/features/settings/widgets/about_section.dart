import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// 关于信息行
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  static const appVersion = '0.1.0';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildRow(context, '应用名称', 'Resource Viewer'),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(context, '版本号', appVersion),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(context, '开源许可', 'MIT License'),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(
            context,
            '反馈',
            'GitHub Issues',
            valueColor: colorScheme.primary,
            onTap: () {
              // 暂无外部反馈渠道，显示提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请通过 GitHub Issues 提交反馈')),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(context, '许可查看', '查看开源许可', onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'Resource Viewer',
              applicationVersion: appVersion,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurfaceVariant = colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: onSurfaceVariant),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
