# 阶段 05 — SMB 网络源

> **定位**：Core | **子阶段数**：11 | **前置依赖**：01（脚手架）, 02（数据层）, 03（本地源链路）
> **目标**：完整的 SMB 网络源支持 — 连接/浏览/文件操作/跨源统一体验

---

## 阶段总体目标

交付 SMB 网络共享的完整支持：添加 SMB 源（配置表单 + 测试连接）、凭据安全存储、SmbFileSource 实现、源可用性检测与自动标记、跨源统一的文件浏览器体验。此阶段完成后，本地文件和 SMB 文件在浏览器和查看器中体验一致。

## 参考文档

| 类型 | 文档 |
|------|------|
| 需求 | `@prd/03-数据源管理.md` §4.1.3（SMB 源）§5.1（连接失败） |
| 技术 | `@tech/01-技术可行性分析.md` §3.1（dart_smb2 评估） |
| 架构 | `@tech/02-架构设计.md` §4.1（FileSource 接口）§8（跨层关注点） |
| 安全 | `@tech/04-数据库设计.md` §4.1（密码不入库） |
| 性能 | `@tech/03-性能优化设计.md` §6（文件浏览缓存 TTL 按源类型） |
| 错误 | `@tech/05-错误处理策略.md` §3（SourceUnreachableError/SourceAuthError） |
| 原型 | `@design/source-list.html`（SMB 弹窗）, `@design/file-browser.html` |

---

## 5.1 SecureStorageService

### 执行目标
封装 `flutter_secure_storage`，提供 SMB 密码的安全存取接口。

### 任务边界
- Key 命名规范：`smb_pwd_{sourceId}`
- 支持存/取/删除

### 产出物
| 文件 | 说明 |
|------|------|
| `lib/data/services/secure_storage_service.dart` | `SecureStorageService` |

### 验收标准
- [ ] `savePassword(sourceId, password)` — 加密存储
- [ ] `getPassword(sourceId)` — 读取明文（用于 SMB 连接）
- [ ] `deletePassword(sourceId)` — 删除（源删除时调用）
- [ ] `hasPassword(sourceId)` — 检查是否已存储
- [ ] 单元测试：mock 验证存取逻辑

---

## 5.2 SmbFileSource 实现

### 执行目标
使用 `dart_smb2` 实现 `FileSource` 接口的 SMB 版本。

### 任务边界
- 连接管理通过 `Smb2Pool`
- `streamFile` 大文件流式读取
- 异常映射：`Smb2Exception` → 原始异常直抛（Repository 层包装）

### 产出物
| 文件 | 说明 |
|------|------|
| `lib/shared/file_source/smb_file_source.dart` | `SmbFileSource` |

### 验收标准
- [ ] `listDirectory(path)` — 返回统一 `FileEntry` 列表
- [ ] `readFile(path)` — 读取文件字节
- [ ] `streamFile(path)` — 流式读取大文件
- [ ] `stat(path)` — 文件/文件夹元数据
- [ ] `testConnection()` — echo() 验证
- [ ] `disconnect()` — 关闭 Smb2Pool 连接
- [ ] 错误时直抛原始异常（不包装，Repository 层包装为 Result）
- [ ] 单元测试：mock Smb2Pool 验证各方法调用

---

## 5.3 SMB 连接池管理

### 执行目标
在 `FileSourceFactory` 中集成 SMB 连接缓存和生命周期管理。

### 任务边界
- SMB 连接复用：同 sourceId 共享一个 SmbFileSource 实例
- 源删除/禁用时 disconnect

### 产出物
| 文件 | 说明 |
|------|------|
| `lib/shared/file_source/file_source_factory.dart` | 扩展 SMB 支持 |

### 验收标准
- [ ] `create(source)` 按 type 路由：`local` → LocalFileSource, `smb` → SmbFileSource
- [ ] SMB 连接池：同 sourceId 复用，不同 sourceId 独立
- [ ] `disconnect(sourceId)` → 调用 smbSource.disconnect() + 移除缓存
- [ ] 源状态变更时自动管理连接

---

## 5.4 SMB 配置表单

### 执行目标
实现添加 SMB 源的配置弹窗：主机地址、端口、用户名、密码、域名。

### 任务边界
- 密码字段脱敏显示 `****`
- 表单校验（必填字段）

### 产出物
| 文件 | 说明 |
|------|------|
| `lib/ui/features/sources/widgets/smb_config_dialog.dart` | `SmbConfigDialog` |

### 验收标准
- [ ] 字段：源名称（必填）/ SMB 地址（必填，格式 `\\host\share`）/ 端口（默认 445）/ 用户名 / 密码 / 域
- [ ] 密码字段：非空时脱敏显示 `****`
- [ ] [测试连接] 按钮
- [ ] 测试成功：[添加] 按钮才可点击
- [ ] 测试失败：红色叉 + 具体错误原因（超时/认证失败/路径不存在）
- [ ] 添加成功：创建 Source 记录 + 密码存入 flutter_secure_storage + `passwordStored = true`
- [ ] 与 `@design/source-list.html` SMB 弹窗布局一致

---

## 5.5 测试连接流程

### 执行目标
实现 SMB 测试连接的端到端流程：表单填写 → 验证凭据 → 反馈结果。

### 任务边界
- 调用 `SmbFileSource.testConnection()`
- 超时处理（15s）
- 错误信息分类展示

### 产出物
| 位置 | 说明 |
|------|------|
| `source_list_view_model.dart` | `testSmbConnection()` 方法 |
| `filesystem_repository.dart` | `testConnection(sourceType, config)` 方法 |

### 验收标准
- [ ] 连接成功：绿色勾 + "连接成功"
- [ ] 连接超时：红色叉 + "连接超时，请检查地址和端口"
- [ ] 认证失败：红色叉 + "认证失败，请检查用户名和密码"
- [ ] 路径不存在：红色叉 + "共享路径不存在"
- [ ] 网络不可达：红色叉 + "无法连接到服务器"
- [ ] 测试过程中按钮显示加载状态，禁止重复点击

---

## 5.6 源可用性检测

### 执行目标
实现数据源可达性的自动检测与 UI 状态更新。

### 任务边界
- 应用启动时检查已启用的 SMB 源
- 源不可达时标记 `isAvailable = false` + 该源资源全标记不可用
- 手动刷新恢复检测

### 产出物
| 位置 | 说明 |
|------|------|
| `source_repository.dart` | `checkAvailability(sourceId)` / `markUnavailable(sourceId)` / `markAvailable(sourceId)` |
| `resource_repository.dart` | `markResourcesUnavailableBySource(sourceId)` |

### 验收标准
- [ ] `markUnavailable` → Source.isAvailable = false + 该源全部 Resource.isAvailable = false
- [ ] `markAvailable` → 恢复可用状态，资源恢复正常
- [ ] 源列表页：不可用源置灰 + 警告图标 + "不可用"文字
- [ ] 首页：不可用源的资源置灰 + "源不可用"标记
- [ ] 文件浏览器：不可用时显示断网占位
- [ ] 手动同步（阶段 07）或网络恢复 → 重新检测

---

## 5.7 源启停切换

### 执行目标
实现数据源的启用/禁用开关。

### 任务边界
- 禁用后该源资源不在首页显示
- SMB 源禁用时断开连接

### 产出物
| 位置 | 说明 |
|------|------|
| `source_list_page.dart` | 开关组件 |
| `source_repository.dart` | `toggleSource(id)` |

### 验收标准
- [ ] 开关切换 → Source.enabled 字段更新
- [ ] 首页查询仅返回 `enabled = true AND isAvailable = true` 源的资源
- [ ] SMB 源禁用时 → disconnect
- [ ] SMB 源重新启用时 → 重新检查可用性

---

## 5.8 删除 SMB 源

### 执行目标
删除 SMB 源的完整流程：确认 → 删除凭据 → disconnect → 级联删除。

### 任务边界
- 清除 flutter_secure_storage 中的密码
- 清除 DirectoryCache 中该源的缓存

### 产出物
| 位置 | 说明 |
|------|------|
| `source_repository.dart` | `deleteSource(id)` 扩展 SMB 清理 |

### 验收标准
- [ ] 二次确认弹窗："确定要删除数据源'xxx'吗？该源下的 N 个资源将被移除，绑定的标签关联也会一并清除。标签本身会保留。"
- [ ] 确认后：删除 flutter_secure_storage 密码 → disconnect → 删除 Source（级联 Resource + ResourceTag）→ 清除缩略图缓存 → 清除 DirectoryCache
- [ ] Tag 保留（关联其他源的资源）

---

## 5.9 跨源统一文件浏览

### 执行目标
确保 `FilesystemRepository` 和文件浏览器对本地/SMB 源提供一致体验。

### 任务边界
- `FileSource.listDirectory()` 已返回统一 `FileEntry`
- 缓存 TTL 按源类型区分（local 30s / SMB 2min）
- 请求去重跨源生效

### 产出物
| 位置 | 说明 |
|------|------|
| `filesystem_repository.dart` | 按源类型设置 TTL |
| `file_browser_page.dart` | 确保 SMB 下骨架屏/加载状态正常 |

### 验收标准
- [ ] 本地源和 SMB 源的文件浏览器 UI 行为一致
- [ ] SMB 目录加载时显示骨架屏
- [ ] SMB 冷加载首次显示，后续 TTL 内缓存命中
- [ ] SMB 返回上级目录：缓存命中无额外网络请求
- [ ] 宽屏双栏：左侧树 + 右侧内容区共享一次 listDirectory（通过去重）

---

## 5.10 SMB 错误处理与降级

### 执行目标
实现 SMB 操作错误的完整分类和用户友好的提示。

### 任务边界
- 所有 SMB 异常在 `FilesystemRepository` 层映射为 `DomainError` 子类

### 产出物
| 位置 | 说明 |
|------|------|
| `filesystem_repository.dart` | SMB 异常 → DomainError 映射 |

### 验收标准
- [ ] `Smb2Exception` 按 type 映射：auth → `SourceAuthError`；connection → `SourceUnreachableError`；timeout → `NetworkTimeoutError`
- [ ] ViewModel 中 `canRetry` = true（这三类错误均允许重试）
- [ ] 错误信息中文文案正确
- [ ] 文件浏览器 error 状态：显示错误提示 + 重试按钮

---

## 5.11 Source 列表状态指示完善

### 执行目标
完善源列表页的源状态视觉反馈。

### 任务边界
- 正常 / 不可达 / 扫描中三种状态

### 产出物
| 位置 | 说明 |
|------|------|
| `source_card.dart` | 状态指示器 |

### 验收标准
- [ ] 正常：正常显示，资源数量
- [ ] 不可达：置灰 + 警告图标 + "不可用"
- [ ] 扫描中：加载动画 + "扫描中..."
- [ ] 禁用：置灰样式 + 开关关闭
