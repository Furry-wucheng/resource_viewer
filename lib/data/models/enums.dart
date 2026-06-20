/// 数据源类型。ftp/webdav 为后续扩展预留。
enum SourceType { local, smb, ftp, webdav }

/// Resource Viewer 支持的资源类型。
///
/// 视频已经进入当前 P0 范围，因此在数据层基础枚举中保留。
enum ResourceType { folder, pdf, archive, video }

/// 资源的组织与浏览方式。
enum OrganizationMode { direct, chapter, flatgrid, gallery }

enum AppThemeMode { system, light, dark }

enum PageDirection { rightToLeft, leftToRight, vertical }

enum DoublePageMode { auto, single, double }

enum AutoSyncInterval { off, minutes15, minutes30, hour1 }
