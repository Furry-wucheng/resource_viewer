# AGENTS.md — Resource Viewer

> Flutter 桌面应用（Windows/macOS/Linux）：多数据源统一收藏管理工具（漫画、图包、PDF）
> 当前状态：阶段 1-4 已完成（脚手架/数据层/本地源链路/标签系统），含文件浏览器、缩略图预览、查看器、标签筛选

## 命令

| 命令 | 用途 |
|------|------|
| `flutter pub get` | 安装依赖 |
| `flutter run -d windows` | 在 Windows 上运行（默认桌面目标） |
| `flutter test` | 运行全部单测 + Widget 测试 |
| `flutter test --coverage` | 带覆盖率 |
| `flutter build windows` | 构建 Windows 发布包 |
| `flutter analyze` | 静态分析（使用 `flutter_lints`） |

## 架构（勿违背）

- **MVVM + Repository**：View → ViewModel (ChangeNotifier) → Repository → Service
- **View 不持有业务状态**，所有状态来自 ViewModel
- **ViewModel 不使用 try/catch** — Repository 将所有错误包装为 `Result<T>`（`Ok` / `Err`）
- **Service 层不捕获异常**，直接抛原始异常；Repository 层捕获并转为 `Result`
- **路由**：`go_router` + `StatefulShellRoute.indexedStack`（3 个底部 Tab：首页/数据源/设置）
  - 查看器和标签管理页使用 `parentNavigatorKey` 全屏覆盖 Tab 栏
  - ResourcePicker / 标签编辑以 `showDialog` 弹窗实现，不走路由
- **依赖注入**：Provider（`MultiProvider`），Service 单例，Repository 依赖 Service，ViewModel 在各 Page 内通过 `ChangeNotifierProvider` 创建

## 两层模型（不要混淆）

| 层 | 位置 | 技术 | 用途 |
|----|------|------|------|
| Domain Model | `lib/domain/models/` | freezed（不可变） | 跨层传递，UI/ViewModel 消费 |
| Data Model | `lib/data/models/` | drift 表定义 | 数据库 schema，不暴露给 UI |

Repository 负责 drift 行 → freezed Domain Model 的转换。

## 关键抽象（策略模式，不可跳过）

- **FileSource** — 统一本地/SMB 文件访问接口（`listDirectory`, `readFile`, `streamFile`, `testConnection`, `disconnect`）
  - 新增数据源类型只需实现此接口 + 在 `FileSourceFactory` 注册
- **ContentProvider** — 查看器翻页抽象（`pageCount`, `loadPage(index)`, `dispose`）
  - 实现：`ImageFolderProvider` / `PdfProvider` / `ArchiveProvider`
- **OrganizationStrategy** — 四种组织模式：`DirectRead` / `Chapter` / `FlatGrid` / `Gallery`
- **ThumbnailGenerator** — 按资源类型路由到不同缩略图生成器

## 错误处理约定

```
UiState 枚举: idle → loading → success / error
Result<T>: sealed class { Ok(value), Err(DomainError) }
流式进度: Progress<T> { ProgressUpdate, ProgressDone, ProgressError }
```

- **预期错误** → `Result` / `Progress`，不用异常
- **编程错误** → `throw`
- View 按 `vm.state` 渲染四种状态；`_ErrorView` 根据 `lastError` 类型调整视觉
- `canRetry` 由 `_lastError` 的类型决定（校验错误不提供重试）
- Fatal 错误（数据库损坏）在 `runApp` 前拦截，显示全屏阻塞页

## 数据库（drift）

- 4 个表：`sources` / `resources` / `tags` / `resource_tags`（关联表）
- **关键 PRAGMA**（每次连接必须执行）：
  ```sql
  PRAGMA foreign_keys = ON;   -- SQLite 默认关闭，级联删除依赖此项
  PRAGMA journal_mode = WAL;
  ```
- SMB 密码**不入库**：`sources.passwordStored` 仅为 bool 标记，实际密码存 `flutter_secure_storage`
- UUID 使用 TEXT 类型，键集分页不能仅靠 UUID 排序（随机），需配合时间戳作为主排序
- `organizationMode` 可为 null（未判定），由 `DetectOrganizationModeUseCase` 异步填充

## 测试

- **mocktail**（非 mockito）：零代码生成，Dart 3 sealed class 兼容
- **drift 不 mock**：全部使用 `NativeDatabase.memory()` 真实内存库
- 五层测试目录结构：`test/domain/` → `test/data/` → `test/ui/` → `test/integration/`
- mock 类集中声明在 `test/helpers/mock_factories.dart`
- 查看器 Widget 测试用 1×1 最小 JPEG 字节，不依赖真实文件
- ViewModel 测试需监听 `notifyListeners` 触发次数，不仅看最终状态

## 依赖

按 `doc/tech/01-技术可行性分析.md` 的推荐列表已添加核心依赖。详见 `pubspec.yaml`。

## 实施顺序

| 顺序 | 内容 | 状态 | 说明 |
|------|------|------|------|
| 1 | 搭建骨架 | ✅ | `app.dart` + go_router + Provider 注册 + 空 Tab 页 |
| 2 | 数据层 | ✅ | drift 表定义 + freezed 模型 + Repository |
| 3 | 本地源链路 | ✅ | LocalFileSource + 文件浏览器 + 缩略图预览 + 查看器 + 视图模式持久化 |
| 4 | 标签系统 | ✅ | Tag CRUD + 筛选栏 + 批量打标签 |
| 5 | SMB 源 | ⬜ | SmbFileSource + SMB 配置 + 测试连接 |
| 6 | 视频播放器 + 画廊模式 | ⬜ | media_kit 视频查看 + GalleryStrategy + 画廊浏览界面 |
| 7 | 缩略图 | ⬜ | ThumbnailGenerator + LRU 缓存 + 首页网格 |
| 8 | 组织模式 | ⬜ | 四种 OrganizationStrategy + 自动判定 |
| 9 | PDF 查看 | ⬜ | PdfRenderService + PdfProvider |
| 10 | 高级功能 | ⬜ | 拆分资源 + ResourcePicker + 章节模式 |
| 11 | 压缩包阅读 | ⬜ | ArchiveProvider + 压缩包内图片浏览 |

## 文档导航

所有需求和技术设计在 `doc/` 中，已定稿：

| 入口 | 内容 |
|------|------|
| [`doc/AGENTS.md`](doc/AGENTS.md) | 文档顶层索引 + 阅读路径 |
| [`doc/prd/AGENTS.md`](doc/prd/AGENTS.md) | 产品定位、术语、模块索引 |
| [`doc/tech/AGENTS.md`](doc/tech/AGENTS.md) | 技术文档索引 + 约定 |
| [`doc/tech/02-架构设计.md`](doc/tech/02-架构设计.md) | 分层 MVVM、目录结构、关键抽象、路由、DI |
| [`doc/tech/04-数据库设计.md`](doc/tech/04-数据库设计.md) | drift 四表 DDL、索引、迁移 |
| [`doc/tech/05-错误处理策略.md`](doc/tech/05-错误处理策略.md) | DomainError 类型树、Result\<T\>、UiState |
| [`doc/tech/06-测试策略.md`](doc/tech/06-测试策略.md) | 五层金字塔、mocktail、drift 内存库 |
| [`doc/design/README.md`](doc/design/README.md) | HTML 交互原型清单 + 设计令牌 |

## 文档间引用格式

- `@01`、`@02` — 同目录下对应编号文档
- `@prd/XX.md` — 从 tech/ 引用 prd/ 文档
- `@design/xxx.html` — 引用 HTML 原型
- 技术文档中的 Dart 代码为设计稿参考，不保证可直接运行。实际代码见 `lib/`。
