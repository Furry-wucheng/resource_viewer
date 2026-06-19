# AGENTS.md — Resource Viewer 文档导航

> 本文件是 `doc/` 目录的顶层索引。开始任何工作前，先阅读本文档和 `doc/prd/AGENTS.md`。

---

## 文件地图

```
doc/
├── AGENTS.md                  ← 你在这里（本文档）
│
├── prd/      产品需求文档 v1.2（已定稿，2026-06-17）
│   ├── AGENTS.md              ← 产品定位、术语、模块索引、核心流程（首选阅读入口）
│   ├── 01-资源库首页.md       模块 A：缩略图网格、筛选栏、空状态、拆分资源
│   ├── 02-标签系统.md         模块 B：内置/自定义标签、交集筛选、批量打标签
│   ├── 03-数据源管理.md       模块 C：本地/SMB 源、文件浏览器（双视图）、批量添加
│   ├── 04-资源查看器.md       模块 D：统一图片/PDF 查看器、滑动条、跨章节、视频
│   ├── 05-数据模型.md         跨模块：Source/Resource/Tag/ResourceTag 实体、关系、数据流转
│   ├── 06-页面结构与交互.md    跨模块：页面树、路由、ResourcePicker 组件、平台适配表
│   ├── 07-资源组织结构.md     模块 A+D：四种组织模式（直接阅读/章节/平铺网格/画廊）
│   └── 08-设置页面.md         跨模块：缓存管理、外观、查看器默认设置
│
├── tech/     技术文档 v1.0（已定稿，2026-06-19）
│   ├── AGENTS.md              ← 技术文档索引，tech↔prd 引用约定
│   ├── 01-技术可行性分析.md    依赖选型（dart_smb2/pdfrx/drift/media_kit）、风险矩阵
│   ├── 02-架构设计.md          MVVM 分层、目录结构、FileSource/ContentProvider/OrganizationStrategy 抽象
│   ├── 03-性能优化设计.md      虚拟滚动、预加载窗口、数据库索引、LRU 缓存、文件浏览去重
│   ├── 04-数据库设计.md        drift 四表 DDL、枚举、索引、级联删除、内置标签播种
│   ├── 05-错误处理策略.md      DomainError 类型树、Result<T>、UiState、Progress 流式错误
│   └── 06-测试策略.md          五层金字塔、mocktail、drift 内存库、测试目录结构
│
├── design/   页面原型 v1.2（HTML + CSS，2026-06-19，已完成）
│   ├── README.md              设计稿清单、合并说明、约定
│   ├── design-tokens.css      公共样式变量（颜色/间距/字体/阴影/响应式网格/浅深主题）
│   ├── homepage.html          资源库首页（正常/空/筛选三态合一）
│   ├── tag-manager.html       标签管理页
│   ├── source-list.html       数据源列表页 + 添加 SMB 弹窗（合并）
│   ├── file-browser.html      文件浏览器（宽屏双栏/窄屏抽屉式）
│   ├── viewer.html            统一查看器（图片+视频混合浏览、单/双页）
│   ├── chapter-list.html      章节列表页
│   ├── resource-detail.html   资源详情弹窗
│   ├── settings.html          设置页
│   └── resource-picker.html   ResourcePicker 弹窗
│
└── mvp/      MVP 分阶段实施计划 v1.0（2026-06-20，刚定稿）
    ├── AGENTS.md               阶段索引、依赖图、使用说明
    ├── 01-项目脚手架与基础UI.md    阶段 1：主题/DI/路由/响应式导航/3 Tab 壳
    ├── 02-数据层与基础设施.md      阶段 2：drift 建表/freezed/Repository/错误处理
    ├── 03-本地源链路.md           阶段 3：LocalFileSource→文件浏览器→查看器→视频→首页网格
    ├── 04-标签系统与筛选.md       阶段 4：Tag CRUD→筛选栏交集筛选→批量打标签→标签管理页
    ├── 05-SMB网络源.md          阶段 5：SmbFileSource→凭据安全→可用性检测→跨源统一
    ├── 06-组织模式与高级查看.md    阶段 6：4 种策略→PDF→画廊→ResourcePicker→拆分资源
    └── 07-设置打磨与测试.md       阶段 7：设置页→ZIP 阅读→性能优化→五层测试覆盖
```

## 阅读路径

### 新人入门（按顺序）

1. [`prd/AGENTS.md`](prd/AGENTS.md) — 产品定位、核心术语、模块概览、用户流程
2. [`prd/05-数据模型.md`](prd/05-数据模型.md) — 所有模块共享的数据实体
3. [`prd/06-页面结构与交互.md`](prd/06-页面结构与交互.md) — 页面层级和导航关系
4. [`tech/AGENTS.md`](tech/AGENTS.md) — 技术文档入口
5. [`tech/01-技术可行性分析.md`](tech/01-技术可行性分析.md) — 选型和风险
6. [`tech/02-架构设计.md`](tech/02-架构设计.md) — 代码如何组织
7. [`design/README.md`](design/README.md) — 原型清单和约定，打开 HTML 查看交互效果
8. [`mvp/AGENTS.md`](mvp/AGENTS.md) — 分阶段实施顺序、依赖图、子阶段索引

### 按任务查文档

| 你要做的 | 先看这些 | 参考原型 |
|----------|---------|---------|
| 实现首页缩略图网格 | prd/01 + tech/02 + tech/03 | `design/homepage.html` |
| 实现标签筛选 | prd/02 + prd/05 + tech/04 | `design/homepage.html`（筛选栏交互） |
| 实现文件浏览器 | prd/03 + prd/06 + tech/02 | `design/file-browser.html` |
| 实现图片/PDF 查看器 | prd/04 + prd/07 + tech/02 + tech/03 | `design/viewer.html` |
| 实现设置页 | prd/08 | `design/settings.html` |
| 实现 ResourcePicker | prd/06 §4.5 + prd/03 | `design/resource-picker.html` |
| 实现标签管理页 | prd/02 §4.6 | `design/tag-manager.html` |
| 添加数据源类型 | tech/02 §4.1（FileSource 接口） | — |
| 写数据库迁移 | tech/04 §9 | — |
| 处理错误 | tech/05 | — |
| 写测试 | tech/06 | — |
| 了解 UI 样式规范 | `design/design-tokens.css` | 颜色/间距/字体/网格/主题 |
| 按阶段实施开发 | `mvp/AGENTS.md` → 对应阶段文件 | `mvp/01~07` 各阶段含验收标准 |

## 四个索引的关系

- **`prd/AGENTS.md`** — 产品向，定义"做什么"。包含术语表和完整模块索引。
- **`tech/AGENTS.md`** — 技术向，定义"怎么做"。记录选型理由和架构约束。
- **`design/README.md`** — 视觉向，HTML 交互原型。含设计清单、合并说明、令牌说明。
- **`mvp/AGENTS.md`** — 实施向，分阶段计划。含依赖图、子阶段清单、验收标准。PRD+Tech+Design 的工程落地路径。
- **`doc/AGENTS.md`**（本文档）— 顶层地图，帮助定位和导航四者。

子索引中已包含的内容（术语定义、模块详情、技术约定、原型清单）本文档不重复。

## 文档间引用格式

| 格式 | 含义 | 在哪个目录使用 |
|------|------|--------------|
| `@01`、`@02` | 同目录下对应编号文档 | prd/ 或 tech/ 内部引用 |
| `@prd/XX.md` | 从 tech/ 引用 prd/ 文档 | tech/ |
| `@design/xxx.html` | 引用 design/ 下的 HTML 原型 | prd/ |
| `@prd/AGENTS.md` | 引用 PRD 的索引 | tech/ |
| `@mvp/` + 文件名 | 引用 mvp/ 下阶段文件 | 任意 |

## 约定

- **术语统一**：Source（数据源）、Resource（资源）、Tag（标签）、OrganizationMode（组织模式）、ResourcePicker。定义见 `prd/AGENTS.md`。
- **两份 AGENTS.md 不重复**：`prd/AGENTS.md` 和 `tech/AGENTS.md` 各自独立，内容不交叉。
- **状态均为"已定稿"**：PRD、技术文档、设计原型均已完成，可直接作为实现依据。
- **技术文档中的代码为设计稿**：Dart 代码片段是架构设计层面的参考，不保证可直接运行。实际代码见 `lib/`。
- **设计原型为交互式 HTML**：每个 HTML 文件内联 JS 实现关键交互演示，零外部依赖（除 Material Icons 字体）。样式统一从 `design-tokens.css` 加载。
- **设计稿有合并**：`homepage.html` 三态合一、`viewer.html` 合并图片+视频混合浏览、`source-list.html` 合并 SMB 弹窗。
- **MVP 实施以阶段文件为准**：每个子阶段含明确的验收标准（可自动化测试或手动检查清单），完成后需通过 `flutter analyze` 零警告。阶段 03 和 04 可并行。
