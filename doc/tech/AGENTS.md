# Resource Viewer — 技术文档

> 版本：v1.0 · 日期：2026-06-19 · 给 AI 阅读

---

## 文档索引

| 编号 | 文档 | 职责 | 状态 |
|------|------|------|------|
| 01 | [技术可行性分析](01-技术可行性分析.md) | 核心技术栈评估、依赖选型、风险矩阵 | 已定稿 |
| 02 | [架构设计](02-架构设计.md) | 分层 MVVM、目录结构、关键抽象、路由、DI、数据流 | 已定稿 |
| 03 | [性能优化设计](03-性能优化设计.md) | 虚拟滚动、查看器预加载、数据库索引、文件浏览缓存、LRU、内存管理 | 已定稿 |
| 04 | [数据库设计](04-数据库设计.md) | 四表 schema、枚举、索引、级联删除、内置标签播种、DAO 查询 | 已定稿 |
| 05 | [错误处理策略](05-错误处理策略.md) | DomainError 类型树、Result\<T\>、跨层约定、UiState、流式 Progress、特殊场景 | 已定稿 |
| 06 | [测试策略](06-测试策略.md) | 五层金字塔、mocktail、drift 内存库、目录结构、CI 命令 | 已定稿 |

---

## 约定

- `@01`、`@02` 等 → 指向同目录下对应编号文档
- `@prd/` + 文件名 → 指向 `doc/prd/` 下的 PRD 文档（如 `@prd/05-数据模型.md`）
- `@prd/AGENTS.md` → PRD 文档索引
- 技术文档记录选型理由、风险、架构约束，不重复 PRD 中的功能描述
- 依赖版本变更时需同步更新本文档

---

## 实施计划

各技术选型的工程落地对应 MVP 阶段如下。开发时以阶段文件的子阶段验收标准为准。

| 技术内容 | MVP 阶段 | 关键文件 |
|----------|---------|---------|
| go_router + StatefulShellRoute | 阶段 01 §1.4~1.5 | `ui/core/router.dart`, `app_shell.dart` |
| Theme + 设计令牌 | 阶段 01 §1.2 | `ui/core/theme/` |
| Provider DI 注册 | 阶段 01 §1.3 | `app.dart` |
| drift 建表 + PRAGMA | 阶段 02 §2.2~2.7 | `data/models/`, `database_service.dart` |
| freezed 领域模型 | 阶段 02 §2.8 | `domain/models/` |
| DomainError + Result\<T\> + UiState | 阶段 02 §2.9 | `domain/models/domain_error.dart`, `result.dart` |
| FileSource 接口 + LocalFileSource | 阶段 03 §3.1~3.3 | `shared/file_source/` |
| ContentProvider 接口 + ImageFolderProvider | 阶段 03 §3.4~3.5 | `shared/content_provider/` |
| ThumbnailGenerator + LRU 缓存 | 阶段 03 §3.6~3.9 | `shared/thumbnail/`, `thumbnail_cache_service.dart` |
| 图片查看器 + extended_image | 阶段 03 §3.18 | `ui/features/viewer/` |
| 视频播放器 + media_kit | 阶段 03 §3.19 | `ui/features/viewer/video_player_page.dart` |
| 标签交集查询 GROUP BY HAVING | 阶段 04 §4.1 | `tag_repository.dart` |
| dart_smb2 + SmbFileSource | 阶段 05 §5.2~5.3 | `shared/file_source/smb_file_source.dart` |
| flutter_secure_storage | 阶段 05 §5.1 | `secure_storage_service.dart` |
| OrganizationStrategy 三种模式 | 阶段 06 §6.1~6.8 | `shared/organization/` |
| pdfrx + PdfProvider | 阶段 06 §6.10 | `shared/content_provider/pdf_provider.dart` |
| archive + ArchiveProvider | 阶段 07 §7.5 | `shared/content_provider/archive_provider.dart` |
| 键集分页 + ImageCache 调优 | 阶段 07 §7.7~7.8 | `resource_repository.dart`, `app.dart` |
| mocktail + drift 内存库测试 | 阶段 07 §7.9~7.13 | `test/` |

> 详见 [`../mvp/AGENTS.md`](../mvp/AGENTS.md)
