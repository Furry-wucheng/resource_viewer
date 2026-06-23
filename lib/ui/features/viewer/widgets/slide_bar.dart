import 'package:flutter/material.dart';

/// 查看器底部滑动条
///
/// 简洁的细线 + 圆点设计，与 design/viewer.html 保持一致。
/// [isRtl] 为 true 时，进度条从右侧开始（日漫模式：第 1 页在右，末页在左）。
class SlideBar extends StatelessWidget {
  const SlideBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
    this.isRtl = false,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onChanged;

  /// 是否为从右向左阅读模式
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pageDisplay = isRtl ? totalPages - currentPage : currentPage + 1;
    final fraction = (currentPage / (totalPages - 1)).clamp(0.0, 1.0);
    final dotFraction = isRtl ? 1.0 - fraction : fraction;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 14,
        top: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final box = context.findRenderObject() as RenderBox;
          final localX = details.localPosition.dx - 16; // subtract left padding
          final barWidth = box.size.width - 32; // subtract both paddings
          if (barWidth <= 0) return;
          final tapFraction = (localX / barWidth).clamp(0.0, 1.0);
          final targetFraction = isRtl ? 1.0 - tapFraction : tapFraction;
          final page = (targetFraction * (totalPages - 1)).round();
          onChanged(page);
        },
        onHorizontalDragUpdate: (details) {
          final box = context.findRenderObject() as RenderBox;
          final barWidth = box.size.width - 32;
          if (barWidth <= 0) return;
          final localX = details.localPosition.dx - 16;
          final tapFraction = (localX / barWidth).clamp(0.0, 1.0);
          final targetFraction = isRtl ? 1.0 - tapFraction : tapFraction;
          final page = (targetFraction * (totalPages - 1)).round();
          onChanged(page);
        },
        child: Row(
          children: [
            // 页码标签
            SizedBox(
              width: 28,
              child: Text(
                '$pageDisplay',
                style: const TextStyle(color: Colors.white60, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // 滑动条
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final dotX = dotFraction * barWidth;
                  return SizedBox(
                    height: 24, // touch target
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // 轨道线
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // 已播放部分
                        Positioned(
                          left: isRtl ? dotX : 0,
                          right: isRtl ? 0 : barWidth - dotX,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // 圆点滑块
                        Positioned(
                          left: dotX - 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            // 总页数标签
            SizedBox(
              width: 28,
              child: Text(
                '$totalPages',
                style: const TextStyle(color: Colors.white60, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
