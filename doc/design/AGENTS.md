# AGENTS.md — Design 原型

> 页面交互原型目录，格式为 HTML 内联 CSS+JS，零框架依赖
> 版本 v1.2，已定稿（2026-06-19）

## 如何查看

直接在浏览器打开任意 `.html` 文件。所有原型共用 `design-tokens.css`（CSS 变量），用相对路径引用。

## 与 Flutter 实现的对应

原型是交互式设计参考，**不是模板**。Flutter 实现时参考布局和交互逻辑，而非复制 HTML 结构。

## 关键事实

- **所有页面共用 `design-tokens.css`**（颜色、间距、字体、阴影、响应式断点、深浅主题）。Flutter 实现时应从中提取设计令牌，而非随意取色。
- **深浅主题**通过 `data-theme="light|dark"` 属性切换 — 原型展示了完整的深浅两套色板。
- **响应式断点**：宽屏模式 ≥ 900px（侧栏 + 双栏布局）
- **Material Icons 字体**是唯一外部依赖（Google Fonts CDN），原型本身不依赖任何 JS 框架

## 未实现或不可见的交互

原型内置了必要的模拟交互，但以下行为因 HTML 限制未完全实现，需参考 PRD：

- 网络请求失败 / 离线状态（如 SMB 不可达、图片加载失败占位）
- 实际文件系统读取（原型用硬编码数据模拟目录结构）
- 键盘快捷键（翻页、全屏、ESC 退出等）
- 数据库相关操作（持久化、迁移）

## 文件清单

| 文件 | 说明 |
|------|------|
| `design-tokens.css` | 公共样式变量（必读） |
| `homepage.html` | 资源库首页 — 三态合一（正常/空/筛选后空），搜索+标签交集筛选 |
| `tag-manager.html` | 标签管理 — 搜索过滤、删除确认弹窗 |
| `source-list.html` | 数据源列表 — FAB 菜单、SMB 添加弹窗（合并自原多个文件） |
| `file-browser.html` | 文件浏览器 — 宽屏双栏/窄屏抽屉、列表/网格视图、多选 |
| `viewer.html` | 统一查看器 — 图片+视频混合、单/双页、滑动条跳页（合并自原多个文件） |
| `chapter-list.html` | 章节列表页 — 响应式双栏布局（≥900dp），grid/list 视图切换，空章节置灰不可点击 |
| `flat-grid.html` | 平铺网格页（含原"直接阅读"场景） — grid/list 切换，文件夹下钻导航（仅返回键），叶子文件夹自动进入设置 |
| `resource-detail.html` | 资源详情弹窗 — 标签勾选、组织模式切换 |
| `settings.html` | 设置 — 缓存容量、开关 toggle、自定义输入 |
| `resource-picker.html` | ResourcePicker 弹窗 — 目录树、多选、计数 |

## 查看器设计要点

- 内容撑满全屏，控件悬浮叠加不挤占内容
- 翻页通过左右半屏点击 + 滑动，无固定翻页箭头
- 底部一行：图片模式 = 页码 + 滑动条 + 全屏；视频模式 = 时间 + 进度条 + 暂停 + 全屏
- 双页模式仅宽度 ≥ 900dp 可用，自动禁用

## 合并说明（源文件已合并，不再存在）

| 原独立文件 | 合并到 |
|------------|--------|
| `homepage-empty.html`, `homepage-filter.html` | `homepage.html` |
| `viewer-immersive.html`, `viewer-toolbar.html`, `viewer-double.html`, `video-player.html` | `viewer.html` |
| `source-add-smb.html` | `source-list.html` |

## 文档间引用格式

PRD 和 Tech 文档中通过 `@design/xxx.html` 引用此目录的文件：
- `@design/homepage.html` — 首页
- `@design/file-browser.html` — 文件浏览器
- `@design/viewer.html` — 查看器
- 以此类推
