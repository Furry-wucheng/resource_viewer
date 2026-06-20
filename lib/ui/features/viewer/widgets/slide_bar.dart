import 'package:flutter/material.dart';

/// 查看器底部滑动条
///
/// 水平滑动条，拖动跳转到指定页面。
class SlideBar extends StatelessWidget {
  const SlideBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Text(
            '${currentPage + 1}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Expanded(
            child: Slider(
              value: currentPage.toDouble(),
              min: 0,
              max: (totalPages - 1).toDouble(),
              onChanged: (value) => onChanged(value.toInt()),
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
            ),
          ),
          Text(
            '$totalPages',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
