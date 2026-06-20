// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_service.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, Source> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SourceType>($SourcesTable.$convertertype);
  static const VerificationMeta _rootPathMeta = const VerificationMeta(
    'rootPath',
  );
  @override
  late final GeneratedColumn<String> rootPath = GeneratedColumn<String>(
    'root_path',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordStoredMeta = const VerificationMeta(
    'passwordStored',
  );
  @override
  late final GeneratedColumn<bool> passwordStored = GeneratedColumn<bool>(
    'password_stored',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("password_stored" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastCheckAtMeta = const VerificationMeta(
    'lastCheckAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckAt = GeneratedColumn<DateTime>(
    'last_check_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    rootPath,
    host,
    port,
    username,
    passwordStored,
    domain,
    enabled,
    isAvailable,
    lastCheckAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Source> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('root_path')) {
      context.handle(
        _rootPathMeta,
        rootPath.isAcceptableOrUnknown(data['root_path']!, _rootPathMeta),
      );
    } else if (isInserting) {
      context.missing(_rootPathMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('password_stored')) {
      context.handle(
        _passwordStoredMeta,
        passwordStored.isAcceptableOrUnknown(
          data['password_stored']!,
          _passwordStoredMeta,
        ),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    if (data.containsKey('last_check_at')) {
      context.handle(
        _lastCheckAtMeta,
        lastCheckAt.isAcceptableOrUnknown(
          data['last_check_at']!,
          _lastCheckAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Source(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $SourcesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      rootPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_path'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      ),
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      passwordStored: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}password_stored'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
      lastCheckAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_check_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceType, String, String> $convertertype =
      const EnumNameConverter<SourceType>(SourceType.values);
}

class Source extends DataClass implements Insertable<Source> {
  /// 主键，UUIDv4
  final String id;

  /// 用户自定义名称
  final String name;

  /// 数据源类型
  final SourceType type;

  /// 根路径，如 D:\Comics 或 smb://192.168.1.100/share
  final String rootPath;

  /// 网络源主机地址
  final String? host;

  /// 端口，默认 445
  final int? port;

  /// 用户名
  final String? username;

  /// 密码是否已存储（实际密码存 flutter_secure_storage）
  final bool passwordStored;

  /// 域/工作组
  final String? domain;

  /// 是否启用（关闭后该源资源不在首页显示）
  final bool enabled;

  /// 当前是否可达
  final bool isAvailable;

  /// 上次连接检查时间
  final DateTime? lastCheckAt;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const Source({
    required this.id,
    required this.name,
    required this.type,
    required this.rootPath,
    this.host,
    this.port,
    this.username,
    required this.passwordStored,
    this.domain,
    required this.enabled,
    required this.isAvailable,
    this.lastCheckAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($SourcesTable.$convertertype.toSql(type));
    }
    map['root_path'] = Variable<String>(rootPath);
    if (!nullToAbsent || host != null) {
      map['host'] = Variable<String>(host);
    }
    if (!nullToAbsent || port != null) {
      map['port'] = Variable<int>(port);
    }
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    map['password_stored'] = Variable<bool>(passwordStored);
    if (!nullToAbsent || domain != null) {
      map['domain'] = Variable<String>(domain);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['is_available'] = Variable<bool>(isAvailable);
    if (!nullToAbsent || lastCheckAt != null) {
      map['last_check_at'] = Variable<DateTime>(lastCheckAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      rootPath: Value(rootPath),
      host: host == null && nullToAbsent ? const Value.absent() : Value(host),
      port: port == null && nullToAbsent ? const Value.absent() : Value(port),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      passwordStored: Value(passwordStored),
      domain: domain == null && nullToAbsent
          ? const Value.absent()
          : Value(domain),
      enabled: Value(enabled),
      isAvailable: Value(isAvailable),
      lastCheckAt: lastCheckAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Source.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $SourcesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      rootPath: serializer.fromJson<String>(json['rootPath']),
      host: serializer.fromJson<String?>(json['host']),
      port: serializer.fromJson<int?>(json['port']),
      username: serializer.fromJson<String?>(json['username']),
      passwordStored: serializer.fromJson<bool>(json['passwordStored']),
      domain: serializer.fromJson<String?>(json['domain']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      lastCheckAt: serializer.fromJson<DateTime?>(json['lastCheckAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $SourcesTable.$convertertype.toJson(type),
      ),
      'rootPath': serializer.toJson<String>(rootPath),
      'host': serializer.toJson<String?>(host),
      'port': serializer.toJson<int?>(port),
      'username': serializer.toJson<String?>(username),
      'passwordStored': serializer.toJson<bool>(passwordStored),
      'domain': serializer.toJson<String?>(domain),
      'enabled': serializer.toJson<bool>(enabled),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'lastCheckAt': serializer.toJson<DateTime?>(lastCheckAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Source copyWith({
    String? id,
    String? name,
    SourceType? type,
    String? rootPath,
    Value<String?> host = const Value.absent(),
    Value<int?> port = const Value.absent(),
    Value<String?> username = const Value.absent(),
    bool? passwordStored,
    Value<String?> domain = const Value.absent(),
    bool? enabled,
    bool? isAvailable,
    Value<DateTime?> lastCheckAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Source(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    rootPath: rootPath ?? this.rootPath,
    host: host.present ? host.value : this.host,
    port: port.present ? port.value : this.port,
    username: username.present ? username.value : this.username,
    passwordStored: passwordStored ?? this.passwordStored,
    domain: domain.present ? domain.value : this.domain,
    enabled: enabled ?? this.enabled,
    isAvailable: isAvailable ?? this.isAvailable,
    lastCheckAt: lastCheckAt.present ? lastCheckAt.value : this.lastCheckAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Source copyWithCompanion(SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      rootPath: data.rootPath.present ? data.rootPath.value : this.rootPath,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      username: data.username.present ? data.username.value : this.username,
      passwordStored: data.passwordStored.present
          ? data.passwordStored.value
          : this.passwordStored,
      domain: data.domain.present ? data.domain.value : this.domain,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
      lastCheckAt: data.lastCheckAt.present
          ? data.lastCheckAt.value
          : this.lastCheckAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('rootPath: $rootPath, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('passwordStored: $passwordStored, ')
          ..write('domain: $domain, ')
          ..write('enabled: $enabled, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('lastCheckAt: $lastCheckAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    rootPath,
    host,
    port,
    username,
    passwordStored,
    domain,
    enabled,
    isAvailable,
    lastCheckAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Source &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.rootPath == this.rootPath &&
          other.host == this.host &&
          other.port == this.port &&
          other.username == this.username &&
          other.passwordStored == this.passwordStored &&
          other.domain == this.domain &&
          other.enabled == this.enabled &&
          other.isAvailable == this.isAvailable &&
          other.lastCheckAt == this.lastCheckAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SourcesCompanion extends UpdateCompanion<Source> {
  final Value<String> id;
  final Value<String> name;
  final Value<SourceType> type;
  final Value<String> rootPath;
  final Value<String?> host;
  final Value<int?> port;
  final Value<String?> username;
  final Value<bool> passwordStored;
  final Value<String?> domain;
  final Value<bool> enabled;
  final Value<bool> isAvailable;
  final Value<DateTime?> lastCheckAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.rootPath = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordStored = const Value.absent(),
    this.domain = const Value.absent(),
    this.enabled = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.lastCheckAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesCompanion.insert({
    required String id,
    required String name,
    required SourceType type,
    required String rootPath,
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordStored = const Value.absent(),
    this.domain = const Value.absent(),
    this.enabled = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.lastCheckAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       rootPath = Value(rootPath);
  static Insertable<Source> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? rootPath,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? username,
    Expression<bool>? passwordStored,
    Expression<String>? domain,
    Expression<bool>? enabled,
    Expression<bool>? isAvailable,
    Expression<DateTime>? lastCheckAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (rootPath != null) 'root_path': rootPath,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (username != null) 'username': username,
      if (passwordStored != null) 'password_stored': passwordStored,
      if (domain != null) 'domain': domain,
      if (enabled != null) 'enabled': enabled,
      if (isAvailable != null) 'is_available': isAvailable,
      if (lastCheckAt != null) 'last_check_at': lastCheckAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<SourceType>? type,
    Value<String>? rootPath,
    Value<String?>? host,
    Value<int?>? port,
    Value<String?>? username,
    Value<bool>? passwordStored,
    Value<String?>? domain,
    Value<bool>? enabled,
    Value<bool>? isAvailable,
    Value<DateTime?>? lastCheckAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rootPath: rootPath ?? this.rootPath,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      passwordStored: passwordStored ?? this.passwordStored,
      domain: domain ?? this.domain,
      enabled: enabled ?? this.enabled,
      isAvailable: isAvailable ?? this.isAvailable,
      lastCheckAt: lastCheckAt ?? this.lastCheckAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $SourcesTable.$convertertype.toSql(type.value),
      );
    }
    if (rootPath.present) {
      map['root_path'] = Variable<String>(rootPath.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordStored.present) {
      map['password_stored'] = Variable<bool>(passwordStored.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (lastCheckAt.present) {
      map['last_check_at'] = Variable<DateTime>(lastCheckAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('rootPath: $rootPath, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('passwordStored: $passwordStored, ')
          ..write('domain: $domain, ')
          ..write('enabled: $enabled, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('lastCheckAt: $lastCheckAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResourcesTable extends Resources
    with TableInfo<$ResourcesTable, Resource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ResourceType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ResourceType>($ResourcesTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<OrganizationMode?, String>
  organizationMode =
      GeneratedColumn<String>(
        'organization_mode',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<OrganizationMode?>(
        $ResourcesTable.$converterorganizationModen,
      );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 1000),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileCountMeta = const VerificationMeta(
    'fileCount',
  );
  @override
  late final GeneratedColumn<int> fileCount = GeneratedColumn<int>(
    'file_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<BigInt> fileSize = GeneratedColumn<BigInt>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastScannedAtMeta = const VerificationMeta(
    'lastScannedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastScannedAt =
      GeneratedColumn<DateTime>(
        'last_scanned_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    name,
    type,
    organizationMode,
    relativePath,
    thumbnailPath,
    fileCount,
    fileSize,
    isAvailable,
    lastScannedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Resource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('file_count')) {
      context.handle(
        _fileCountMeta,
        fileCount.isAcceptableOrUnknown(data['file_count']!, _fileCountMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    if (data.containsKey('last_scanned_at')) {
      context.handle(
        _lastScannedAtMeta,
        lastScannedAt.isAcceptableOrUnknown(
          data['last_scanned_at']!,
          _lastScannedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceId, relativePath},
  ];
  @override
  Resource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Resource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $ResourcesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      organizationMode: $ResourcesTable.$converterorganizationModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}organization_mode'],
        ),
      ),
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      fileCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_count'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}file_size'],
      ),
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
      lastScannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_scanned_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ResourcesTable createAlias(String alias) {
    return $ResourcesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ResourceType, String, String> $convertertype =
      const EnumNameConverter<ResourceType>(ResourceType.values);
  static JsonTypeConverter2<OrganizationMode, String, String>
  $converterorganizationMode = const EnumNameConverter<OrganizationMode>(
    OrganizationMode.values,
  );
  static JsonTypeConverter2<OrganizationMode?, String?, String?>
  $converterorganizationModen = JsonTypeConverter2.asNullable(
    $converterorganizationMode,
  );
}

class Resource extends DataClass implements Insertable<Resource> {
  /// 主键，UUIDv4
  final String id;

  /// 所属数据源 ID（外键）
  final String sourceId;

  /// 资源名称（文件夹名或文件名）
  final String name;

  /// 资源类型
  final ResourceType type;

  /// 组织模式（null = 未判定）
  final OrganizationMode? organizationMode;

  /// 相对于源根目录的路径
  final String relativePath;

  /// 本地缓存缩略图路径
  final String? thumbnailPath;

  /// 内部图片/页数
  final int? fileCount;

  /// 文件大小（字节）
  final BigInt? fileSize;

  /// 文件当前是否可访问
  final bool isAvailable;

  /// 最后扫描时间
  final DateTime? lastScannedAt;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const Resource({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.type,
    this.organizationMode,
    required this.relativePath,
    this.thumbnailPath,
    this.fileCount,
    this.fileSize,
    required this.isAvailable,
    this.lastScannedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $ResourcesTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || organizationMode != null) {
      map['organization_mode'] = Variable<String>(
        $ResourcesTable.$converterorganizationModen.toSql(organizationMode),
      );
    }
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || fileCount != null) {
      map['file_count'] = Variable<int>(fileCount);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<BigInt>(fileSize);
    }
    map['is_available'] = Variable<bool>(isAvailable);
    if (!nullToAbsent || lastScannedAt != null) {
      map['last_scanned_at'] = Variable<DateTime>(lastScannedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ResourcesCompanion toCompanion(bool nullToAbsent) {
    return ResourcesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      name: Value(name),
      type: Value(type),
      organizationMode: organizationMode == null && nullToAbsent
          ? const Value.absent()
          : Value(organizationMode),
      relativePath: Value(relativePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      fileCount: fileCount == null && nullToAbsent
          ? const Value.absent()
          : Value(fileCount),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      isAvailable: Value(isAvailable),
      lastScannedAt: lastScannedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScannedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Resource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Resource(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      name: serializer.fromJson<String>(json['name']),
      type: $ResourcesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      organizationMode: $ResourcesTable.$converterorganizationModen.fromJson(
        serializer.fromJson<String?>(json['organizationMode']),
      ),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      fileCount: serializer.fromJson<int?>(json['fileCount']),
      fileSize: serializer.fromJson<BigInt?>(json['fileSize']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      lastScannedAt: serializer.fromJson<DateTime?>(json['lastScannedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $ResourcesTable.$convertertype.toJson(type),
      ),
      'organizationMode': serializer.toJson<String?>(
        $ResourcesTable.$converterorganizationModen.toJson(organizationMode),
      ),
      'relativePath': serializer.toJson<String>(relativePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'fileCount': serializer.toJson<int?>(fileCount),
      'fileSize': serializer.toJson<BigInt?>(fileSize),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'lastScannedAt': serializer.toJson<DateTime?>(lastScannedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Resource copyWith({
    String? id,
    String? sourceId,
    String? name,
    ResourceType? type,
    Value<OrganizationMode?> organizationMode = const Value.absent(),
    String? relativePath,
    Value<String?> thumbnailPath = const Value.absent(),
    Value<int?> fileCount = const Value.absent(),
    Value<BigInt?> fileSize = const Value.absent(),
    bool? isAvailable,
    Value<DateTime?> lastScannedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Resource(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    name: name ?? this.name,
    type: type ?? this.type,
    organizationMode: organizationMode.present
        ? organizationMode.value
        : this.organizationMode,
    relativePath: relativePath ?? this.relativePath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    fileCount: fileCount.present ? fileCount.value : this.fileCount,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    isAvailable: isAvailable ?? this.isAvailable,
    lastScannedAt: lastScannedAt.present
        ? lastScannedAt.value
        : this.lastScannedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Resource copyWithCompanion(ResourcesCompanion data) {
    return Resource(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      organizationMode: data.organizationMode.present
          ? data.organizationMode.value
          : this.organizationMode,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      fileCount: data.fileCount.present ? data.fileCount.value : this.fileCount,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
      lastScannedAt: data.lastScannedAt.present
          ? data.lastScannedAt.value
          : this.lastScannedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Resource(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('organizationMode: $organizationMode, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('fileCount: $fileCount, ')
          ..write('fileSize: $fileSize, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('lastScannedAt: $lastScannedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    name,
    type,
    organizationMode,
    relativePath,
    thumbnailPath,
    fileCount,
    fileSize,
    isAvailable,
    lastScannedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Resource &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.name == this.name &&
          other.type == this.type &&
          other.organizationMode == this.organizationMode &&
          other.relativePath == this.relativePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.fileCount == this.fileCount &&
          other.fileSize == this.fileSize &&
          other.isAvailable == this.isAvailable &&
          other.lastScannedAt == this.lastScannedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ResourcesCompanion extends UpdateCompanion<Resource> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String> name;
  final Value<ResourceType> type;
  final Value<OrganizationMode?> organizationMode;
  final Value<String> relativePath;
  final Value<String?> thumbnailPath;
  final Value<int?> fileCount;
  final Value<BigInt?> fileSize;
  final Value<bool> isAvailable;
  final Value<DateTime?> lastScannedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ResourcesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.organizationMode = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.lastScannedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResourcesCompanion.insert({
    required String id,
    required String sourceId,
    required String name,
    required ResourceType type,
    this.organizationMode = const Value.absent(),
    required String relativePath,
    this.thumbnailPath = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.lastScannedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       name = Value(name),
       type = Value(type),
       relativePath = Value(relativePath);
  static Insertable<Resource> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? organizationMode,
    Expression<String>? relativePath,
    Expression<String>? thumbnailPath,
    Expression<int>? fileCount,
    Expression<BigInt>? fileSize,
    Expression<bool>? isAvailable,
    Expression<DateTime>? lastScannedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (organizationMode != null) 'organization_mode': organizationMode,
      if (relativePath != null) 'relative_path': relativePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (fileCount != null) 'file_count': fileCount,
      if (fileSize != null) 'file_size': fileSize,
      if (isAvailable != null) 'is_available': isAvailable,
      if (lastScannedAt != null) 'last_scanned_at': lastScannedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String>? name,
    Value<ResourceType>? type,
    Value<OrganizationMode?>? organizationMode,
    Value<String>? relativePath,
    Value<String?>? thumbnailPath,
    Value<int?>? fileCount,
    Value<BigInt?>? fileSize,
    Value<bool>? isAvailable,
    Value<DateTime?>? lastScannedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ResourcesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      type: type ?? this.type,
      organizationMode: organizationMode ?? this.organizationMode,
      relativePath: relativePath ?? this.relativePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileCount: fileCount ?? this.fileCount,
      fileSize: fileSize ?? this.fileSize,
      isAvailable: isAvailable ?? this.isAvailable,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $ResourcesTable.$convertertype.toSql(type.value),
      );
    }
    if (organizationMode.present) {
      map['organization_mode'] = Variable<String>(
        $ResourcesTable.$converterorganizationModen.toSql(
          organizationMode.value,
        ),
      );
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (fileCount.present) {
      map['file_count'] = Variable<int>(fileCount.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<BigInt>(fileSize.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (lastScannedAt.present) {
      map['last_scanned_at'] = Variable<DateTime>(lastScannedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResourcesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('organizationMode: $organizationMode, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('fileCount: $fileCount, ')
          ..write('fileSize: $fileSize, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('lastScannedAt: $lastScannedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 7),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    isBuiltIn,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  /// 主键，UUIDv4（内置标签使用固定 UUID）
  final String id;

  /// 标签名称（唯一）
  final String name;

  /// HEX 颜色值 #RRGGBB
  final String color;

  /// 是否为内置标签（内置标签不可删除/重命名）
  final bool isBuiltIn;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.isBuiltIn,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      isBuiltIn: Value(isBuiltIn),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    String? color,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, isBuiltIn, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.isBuiltIn == this.isBuiltIn &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> color;
  final Value<bool> isBuiltIn;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required String color,
    this.isBuiltIn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<bool>? isBuiltIn,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? color,
    Value<bool>? isBuiltIn,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResourceTagsTable extends ResourceTags
    with TableInfo<$ResourceTagsTable, ResourceTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResourceTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES resources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [resourceId, tagId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resource_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResourceTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId, tagId};
  @override
  ResourceTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResourceTag(
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ResourceTagsTable createAlias(String alias) {
    return $ResourceTagsTable(attachedDatabase, alias);
  }
}

class ResourceTag extends DataClass implements Insertable<ResourceTag> {
  /// 资源 ID（外键，联合主键之一）
  final String resourceId;

  /// 标签 ID（外键，联合主键之一）
  final String tagId;

  /// 创建时间
  final DateTime createdAt;
  const ResourceTag({
    required this.resourceId,
    required this.tagId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['tag_id'] = Variable<String>(tagId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ResourceTagsCompanion toCompanion(bool nullToAbsent) {
    return ResourceTagsCompanion(
      resourceId: Value(resourceId),
      tagId: Value(tagId),
      createdAt: Value(createdAt),
    );
  }

  factory ResourceTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResourceTag(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      tagId: serializer.fromJson<String>(json['tagId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'tagId': serializer.toJson<String>(tagId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ResourceTag copyWith({
    String? resourceId,
    String? tagId,
    DateTime? createdAt,
  }) => ResourceTag(
    resourceId: resourceId ?? this.resourceId,
    tagId: tagId ?? this.tagId,
    createdAt: createdAt ?? this.createdAt,
  );
  ResourceTag copyWithCompanion(ResourceTagsCompanion data) {
    return ResourceTag(
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResourceTag(')
          ..write('resourceId: $resourceId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceId, tagId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResourceTag &&
          other.resourceId == this.resourceId &&
          other.tagId == this.tagId &&
          other.createdAt == this.createdAt);
}

class ResourceTagsCompanion extends UpdateCompanion<ResourceTag> {
  final Value<String> resourceId;
  final Value<String> tagId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ResourceTagsCompanion({
    this.resourceId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResourceTagsCompanion.insert({
    required String resourceId,
    required String tagId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : resourceId = Value(resourceId),
       tagId = Value(tagId);
  static Insertable<ResourceTag> custom({
    Expression<String>? resourceId,
    Expression<String>? tagId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (tagId != null) 'tag_id': tagId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResourceTagsCompanion copyWith({
    Value<String>? resourceId,
    Value<String>? tagId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ResourceTagsCompanion(
      resourceId: resourceId ?? this.resourceId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResourceTagsCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppConfigTable extends AppConfig
    with TableInfo<$AppConfigTable, AppConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AppThemeMode, String> themeMode =
      GeneratedColumn<String>(
        'theme_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(AppThemeMode.system.name),
      ).withConverter<AppThemeMode>($AppConfigTable.$converterthemeMode);
  @override
  late final GeneratedColumnWithTypeConverter<PageDirection, String>
  pageDirection = GeneratedColumn<String>(
    'page_direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(PageDirection.rightToLeft.name),
  ).withConverter<PageDirection>($AppConfigTable.$converterpageDirection);
  @override
  late final GeneratedColumnWithTypeConverter<DoublePageMode, String>
  doublePageMode = GeneratedColumn<String>(
    'double_page_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(DoublePageMode.auto.name),
  ).withConverter<DoublePageMode>($AppConfigTable.$converterdoublePageMode);
  static const VerificationMeta _crossChapterMeta = const VerificationMeta(
    'crossChapter',
  );
  @override
  late final GeneratedColumn<bool> crossChapter = GeneratedColumn<bool>(
    'cross_chapter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cross_chapter" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cacheLimitMBMeta = const VerificationMeta(
    'cacheLimitMB',
  );
  @override
  late final GeneratedColumn<int> cacheLimitMB = GeneratedColumn<int>(
    'cache_limit_m_b',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(500),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AutoSyncInterval, String>
  autoSyncInterval = GeneratedColumn<String>(
    'auto_sync_interval',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(AutoSyncInterval.off.name),
  ).withConverter<AutoSyncInterval>($AppConfigTable.$converterautoSyncInterval);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    pageDirection,
    doublePageMode,
    crossChapter,
    cacheLimitMB,
    autoSyncInterval,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cross_chapter')) {
      context.handle(
        _crossChapterMeta,
        crossChapter.isAcceptableOrUnknown(
          data['cross_chapter']!,
          _crossChapterMeta,
        ),
      );
    }
    if (data.containsKey('cache_limit_m_b')) {
      context.handle(
        _cacheLimitMBMeta,
        cacheLimitMB.isAcceptableOrUnknown(
          data['cache_limit_m_b']!,
          _cacheLimitMBMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppConfigRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      themeMode: $AppConfigTable.$converterthemeMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}theme_mode'],
        )!,
      ),
      pageDirection: $AppConfigTable.$converterpageDirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}page_direction'],
        )!,
      ),
      doublePageMode: $AppConfigTable.$converterdoublePageMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}double_page_mode'],
        )!,
      ),
      crossChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cross_chapter'],
      )!,
      cacheLimitMB: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_limit_m_b'],
      )!,
      autoSyncInterval: $AppConfigTable.$converterautoSyncInterval.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}auto_sync_interval'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppConfigTable createAlias(String alias) {
    return $AppConfigTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AppThemeMode, String, String> $converterthemeMode =
      const EnumNameConverter<AppThemeMode>(AppThemeMode.values);
  static JsonTypeConverter2<PageDirection, String, String>
  $converterpageDirection = const EnumNameConverter<PageDirection>(
    PageDirection.values,
  );
  static JsonTypeConverter2<DoublePageMode, String, String>
  $converterdoublePageMode = const EnumNameConverter<DoublePageMode>(
    DoublePageMode.values,
  );
  static JsonTypeConverter2<AutoSyncInterval, String, String>
  $converterautoSyncInterval = const EnumNameConverter<AutoSyncInterval>(
    AutoSyncInterval.values,
  );
}

class AppConfigRow extends DataClass implements Insertable<AppConfigRow> {
  final int id;
  final AppThemeMode themeMode;
  final PageDirection pageDirection;
  final DoublePageMode doublePageMode;
  final bool crossChapter;
  final int cacheLimitMB;
  final AutoSyncInterval autoSyncInterval;
  final DateTime updatedAt;
  const AppConfigRow({
    required this.id,
    required this.themeMode,
    required this.pageDirection,
    required this.doublePageMode,
    required this.crossChapter,
    required this.cacheLimitMB,
    required this.autoSyncInterval,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['theme_mode'] = Variable<String>(
        $AppConfigTable.$converterthemeMode.toSql(themeMode),
      );
    }
    {
      map['page_direction'] = Variable<String>(
        $AppConfigTable.$converterpageDirection.toSql(pageDirection),
      );
    }
    {
      map['double_page_mode'] = Variable<String>(
        $AppConfigTable.$converterdoublePageMode.toSql(doublePageMode),
      );
    }
    map['cross_chapter'] = Variable<bool>(crossChapter);
    map['cache_limit_m_b'] = Variable<int>(cacheLimitMB);
    {
      map['auto_sync_interval'] = Variable<String>(
        $AppConfigTable.$converterautoSyncInterval.toSql(autoSyncInterval),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppConfigCompanion toCompanion(bool nullToAbsent) {
    return AppConfigCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      pageDirection: Value(pageDirection),
      doublePageMode: Value(doublePageMode),
      crossChapter: Value(crossChapter),
      cacheLimitMB: Value(cacheLimitMB),
      autoSyncInterval: Value(autoSyncInterval),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppConfigRow(
      id: serializer.fromJson<int>(json['id']),
      themeMode: $AppConfigTable.$converterthemeMode.fromJson(
        serializer.fromJson<String>(json['themeMode']),
      ),
      pageDirection: $AppConfigTable.$converterpageDirection.fromJson(
        serializer.fromJson<String>(json['pageDirection']),
      ),
      doublePageMode: $AppConfigTable.$converterdoublePageMode.fromJson(
        serializer.fromJson<String>(json['doublePageMode']),
      ),
      crossChapter: serializer.fromJson<bool>(json['crossChapter']),
      cacheLimitMB: serializer.fromJson<int>(json['cacheLimitMB']),
      autoSyncInterval: $AppConfigTable.$converterautoSyncInterval.fromJson(
        serializer.fromJson<String>(json['autoSyncInterval']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themeMode': serializer.toJson<String>(
        $AppConfigTable.$converterthemeMode.toJson(themeMode),
      ),
      'pageDirection': serializer.toJson<String>(
        $AppConfigTable.$converterpageDirection.toJson(pageDirection),
      ),
      'doublePageMode': serializer.toJson<String>(
        $AppConfigTable.$converterdoublePageMode.toJson(doublePageMode),
      ),
      'crossChapter': serializer.toJson<bool>(crossChapter),
      'cacheLimitMB': serializer.toJson<int>(cacheLimitMB),
      'autoSyncInterval': serializer.toJson<String>(
        $AppConfigTable.$converterautoSyncInterval.toJson(autoSyncInterval),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppConfigRow copyWith({
    int? id,
    AppThemeMode? themeMode,
    PageDirection? pageDirection,
    DoublePageMode? doublePageMode,
    bool? crossChapter,
    int? cacheLimitMB,
    AutoSyncInterval? autoSyncInterval,
    DateTime? updatedAt,
  }) => AppConfigRow(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    pageDirection: pageDirection ?? this.pageDirection,
    doublePageMode: doublePageMode ?? this.doublePageMode,
    crossChapter: crossChapter ?? this.crossChapter,
    cacheLimitMB: cacheLimitMB ?? this.cacheLimitMB,
    autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppConfigRow copyWithCompanion(AppConfigCompanion data) {
    return AppConfigRow(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      pageDirection: data.pageDirection.present
          ? data.pageDirection.value
          : this.pageDirection,
      doublePageMode: data.doublePageMode.present
          ? data.doublePageMode.value
          : this.doublePageMode,
      crossChapter: data.crossChapter.present
          ? data.crossChapter.value
          : this.crossChapter,
      cacheLimitMB: data.cacheLimitMB.present
          ? data.cacheLimitMB.value
          : this.cacheLimitMB,
      autoSyncInterval: data.autoSyncInterval.present
          ? data.autoSyncInterval.value
          : this.autoSyncInterval,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppConfigRow(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('pageDirection: $pageDirection, ')
          ..write('doublePageMode: $doublePageMode, ')
          ..write('crossChapter: $crossChapter, ')
          ..write('cacheLimitMB: $cacheLimitMB, ')
          ..write('autoSyncInterval: $autoSyncInterval, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themeMode,
    pageDirection,
    doublePageMode,
    crossChapter,
    cacheLimitMB,
    autoSyncInterval,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppConfigRow &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.pageDirection == this.pageDirection &&
          other.doublePageMode == this.doublePageMode &&
          other.crossChapter == this.crossChapter &&
          other.cacheLimitMB == this.cacheLimitMB &&
          other.autoSyncInterval == this.autoSyncInterval &&
          other.updatedAt == this.updatedAt);
}

class AppConfigCompanion extends UpdateCompanion<AppConfigRow> {
  final Value<int> id;
  final Value<AppThemeMode> themeMode;
  final Value<PageDirection> pageDirection;
  final Value<DoublePageMode> doublePageMode;
  final Value<bool> crossChapter;
  final Value<int> cacheLimitMB;
  final Value<AutoSyncInterval> autoSyncInterval;
  final Value<DateTime> updatedAt;
  const AppConfigCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.pageDirection = const Value.absent(),
    this.doublePageMode = const Value.absent(),
    this.crossChapter = const Value.absent(),
    this.cacheLimitMB = const Value.absent(),
    this.autoSyncInterval = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppConfigCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.pageDirection = const Value.absent(),
    this.doublePageMode = const Value.absent(),
    this.crossChapter = const Value.absent(),
    this.cacheLimitMB = const Value.absent(),
    this.autoSyncInterval = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<AppConfigRow> custom({
    Expression<int>? id,
    Expression<String>? themeMode,
    Expression<String>? pageDirection,
    Expression<String>? doublePageMode,
    Expression<bool>? crossChapter,
    Expression<int>? cacheLimitMB,
    Expression<String>? autoSyncInterval,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (pageDirection != null) 'page_direction': pageDirection,
      if (doublePageMode != null) 'double_page_mode': doublePageMode,
      if (crossChapter != null) 'cross_chapter': crossChapter,
      if (cacheLimitMB != null) 'cache_limit_m_b': cacheLimitMB,
      if (autoSyncInterval != null) 'auto_sync_interval': autoSyncInterval,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppConfigCompanion copyWith({
    Value<int>? id,
    Value<AppThemeMode>? themeMode,
    Value<PageDirection>? pageDirection,
    Value<DoublePageMode>? doublePageMode,
    Value<bool>? crossChapter,
    Value<int>? cacheLimitMB,
    Value<AutoSyncInterval>? autoSyncInterval,
    Value<DateTime>? updatedAt,
  }) {
    return AppConfigCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      pageDirection: pageDirection ?? this.pageDirection,
      doublePageMode: doublePageMode ?? this.doublePageMode,
      crossChapter: crossChapter ?? this.crossChapter,
      cacheLimitMB: cacheLimitMB ?? this.cacheLimitMB,
      autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(
        $AppConfigTable.$converterthemeMode.toSql(themeMode.value),
      );
    }
    if (pageDirection.present) {
      map['page_direction'] = Variable<String>(
        $AppConfigTable.$converterpageDirection.toSql(pageDirection.value),
      );
    }
    if (doublePageMode.present) {
      map['double_page_mode'] = Variable<String>(
        $AppConfigTable.$converterdoublePageMode.toSql(doublePageMode.value),
      );
    }
    if (crossChapter.present) {
      map['cross_chapter'] = Variable<bool>(crossChapter.value);
    }
    if (cacheLimitMB.present) {
      map['cache_limit_m_b'] = Variable<int>(cacheLimitMB.value);
    }
    if (autoSyncInterval.present) {
      map['auto_sync_interval'] = Variable<String>(
        $AppConfigTable.$converterautoSyncInterval.toSql(
          autoSyncInterval.value,
        ),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppConfigCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('pageDirection: $pageDirection, ')
          ..write('doublePageMode: $doublePageMode, ')
          ..write('crossChapter: $crossChapter, ')
          ..write('cacheLimitMB: $cacheLimitMB, ')
          ..write('autoSyncInterval: $autoSyncInterval, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $ResourcesTable resources = $ResourcesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ResourceTagsTable resourceTags = $ResourceTagsTable(this);
  late final $AppConfigTable appConfig = $AppConfigTable(this);
  late final Index idxResourcesCreatedAtId = Index(
    'idx_resources_created_at_id',
    'CREATE INDEX idx_resources_created_at_id ON resources (created_at, id)',
  );
  late final Index idxResourcesNameId = Index(
    'idx_resources_name_id',
    'CREATE INDEX idx_resources_name_id ON resources (name, id)',
  );
  late final Index idxRtTagResource = Index(
    'idx_rt_tag_resource',
    'CREATE INDEX idx_rt_tag_resource ON resource_tags (tag_id, resource_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    resources,
    tags,
    resourceTags,
    appConfig,
    idxResourcesCreatedAtId,
    idxResourcesNameId,
    idxRtTagResource,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('resources', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'resources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('resource_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('resource_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      required String id,
      required String name,
      required SourceType type,
      required String rootPath,
      Value<String?> host,
      Value<int?> port,
      Value<String?> username,
      Value<bool> passwordStored,
      Value<String?> domain,
      Value<bool> enabled,
      Value<bool> isAvailable,
      Value<DateTime?> lastCheckAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<SourceType> type,
      Value<String> rootPath,
      Value<String?> host,
      Value<int?> port,
      Value<String?> username,
      Value<bool> passwordStored,
      Value<String?> domain,
      Value<bool> enabled,
      Value<bool> isAvailable,
      Value<DateTime?> lastCheckAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SourcesTableReferences
    extends BaseReferences<_$AppDatabase, $SourcesTable, Source> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ResourcesTable, List<Resource>>
  _resourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.resources,
    aliasName: 'sources__id__resources__source_id',
  );

  $$ResourcesTableProcessedTableManager get resourcesRefs {
    final manager = $$ResourcesTableTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_resourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SourceType, SourceType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get rootPath => $composableBuilder(
    column: $table.rootPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get passwordStored => $composableBuilder(
    column: $table.passwordStored,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCheckAt => $composableBuilder(
    column: $table.lastCheckAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> resourcesRefs(
    Expression<bool> Function($$ResourcesTableFilterComposer f) f,
  ) {
    final $$ResourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootPath => $composableBuilder(
    column: $table.rootPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get passwordStored => $composableBuilder(
    column: $table.passwordStored,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCheckAt => $composableBuilder(
    column: $table.lastCheckAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SourceType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get rootPath =>
      $composableBuilder(column: $table.rootPath, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<bool> get passwordStored => $composableBuilder(
    column: $table.passwordStored,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCheckAt => $composableBuilder(
    column: $table.lastCheckAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> resourcesRefs<T extends Object>(
    Expression<T> Function($$ResourcesTableAnnotationComposer a) f,
  ) {
    final $$ResourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          Source,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (Source, $$SourcesTableReferences),
          Source,
          PrefetchHooks Function({bool resourcesRefs})
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<SourceType> type = const Value.absent(),
                Value<String> rootPath = const Value.absent(),
                Value<String?> host = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<bool> passwordStored = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<DateTime?> lastCheckAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                name: name,
                type: type,
                rootPath: rootPath,
                host: host,
                port: port,
                username: username,
                passwordStored: passwordStored,
                domain: domain,
                enabled: enabled,
                isAvailable: isAvailable,
                lastCheckAt: lastCheckAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required SourceType type,
                required String rootPath,
                Value<String?> host = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<bool> passwordStored = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<DateTime?> lastCheckAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                name: name,
                type: type,
                rootPath: rootPath,
                host: host,
                port: port,
                username: username,
                passwordStored: passwordStored,
                domain: domain,
                enabled: enabled,
                isAvailable: isAvailable,
                lastCheckAt: lastCheckAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resourcesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (resourcesRefs) db.resources],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (resourcesRefs)
                    await $_getPrefetchedData<Source, $SourcesTable, Resource>(
                      currentTable: table,
                      referencedTable: $$SourcesTableReferences
                          ._resourcesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SourcesTableReferences(db, table, p0).resourcesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sourceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      Source,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (Source, $$SourcesTableReferences),
      Source,
      PrefetchHooks Function({bool resourcesRefs})
    >;
typedef $$ResourcesTableCreateCompanionBuilder =
    ResourcesCompanion Function({
      required String id,
      required String sourceId,
      required String name,
      required ResourceType type,
      Value<OrganizationMode?> organizationMode,
      required String relativePath,
      Value<String?> thumbnailPath,
      Value<int?> fileCount,
      Value<BigInt?> fileSize,
      Value<bool> isAvailable,
      Value<DateTime?> lastScannedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ResourcesTableUpdateCompanionBuilder =
    ResourcesCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String> name,
      Value<ResourceType> type,
      Value<OrganizationMode?> organizationMode,
      Value<String> relativePath,
      Value<String?> thumbnailPath,
      Value<int?> fileCount,
      Value<BigInt?> fileSize,
      Value<bool> isAvailable,
      Value<DateTime?> lastScannedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ResourcesTableReferences
    extends BaseReferences<_$AppDatabase, $ResourcesTable, Resource> {
  $$ResourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias('resources__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ResourceTagsTable, List<ResourceTag>>
  _resourceTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.resourceTags,
    aliasName: 'resources__id__resource_tags__resource_id',
  );

  $$ResourceTagsTableProcessedTableManager get resourceTagsRefs {
    final manager = $$ResourceTagsTableTableManager(
      $_db,
      $_db.resourceTags,
    ).filter((f) => f.resourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_resourceTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ResourcesTableFilterComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ResourceType, ResourceType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<OrganizationMode?, OrganizationMode, String>
  get organizationMode => $composableBuilder(
    column: $table.organizationMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastScannedAt => $composableBuilder(
    column: $table.lastScannedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> resourceTagsRefs(
    Expression<bool> Function($$ResourceTagsTableFilterComposer f) f,
  ) {
    final $$ResourceTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resourceTags,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourceTagsTableFilterComposer(
            $db: $db,
            $table: $db.resourceTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ResourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationMode => $composableBuilder(
    column: $table.organizationMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastScannedAt => $composableBuilder(
    column: $table.lastScannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ResourceType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OrganizationMode?, String>
  get organizationMode => $composableBuilder(
    column: $table.organizationMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileCount =>
      $composableBuilder(column: $table.fileCount, builder: (column) => column);

  GeneratedColumn<BigInt> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastScannedAt => $composableBuilder(
    column: $table.lastScannedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> resourceTagsRefs<T extends Object>(
    Expression<T> Function($$ResourceTagsTableAnnotationComposer a) f,
  ) {
    final $$ResourceTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resourceTags,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourceTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.resourceTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ResourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResourcesTable,
          Resource,
          $$ResourcesTableFilterComposer,
          $$ResourcesTableOrderingComposer,
          $$ResourcesTableAnnotationComposer,
          $$ResourcesTableCreateCompanionBuilder,
          $$ResourcesTableUpdateCompanionBuilder,
          (Resource, $$ResourcesTableReferences),
          Resource,
          PrefetchHooks Function({bool sourceId, bool resourceTagsRefs})
        > {
  $$ResourcesTableTableManager(_$AppDatabase db, $ResourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ResourceType> type = const Value.absent(),
                Value<OrganizationMode?> organizationMode =
                    const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int?> fileCount = const Value.absent(),
                Value<BigInt?> fileSize = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<DateTime?> lastScannedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResourcesCompanion(
                id: id,
                sourceId: sourceId,
                name: name,
                type: type,
                organizationMode: organizationMode,
                relativePath: relativePath,
                thumbnailPath: thumbnailPath,
                fileCount: fileCount,
                fileSize: fileSize,
                isAvailable: isAvailable,
                lastScannedAt: lastScannedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                required String name,
                required ResourceType type,
                Value<OrganizationMode?> organizationMode =
                    const Value.absent(),
                required String relativePath,
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int?> fileCount = const Value.absent(),
                Value<BigInt?> fileSize = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<DateTime?> lastScannedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResourcesCompanion.insert(
                id: id,
                sourceId: sourceId,
                name: name,
                type: type,
                organizationMode: organizationMode,
                relativePath: relativePath,
                thumbnailPath: thumbnailPath,
                fileCount: fileCount,
                fileSize: fileSize,
                isAvailable: isAvailable,
                lastScannedAt: lastScannedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceId = false, resourceTagsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (resourceTagsRefs) db.resourceTags,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceId,
                                    referencedTable: $$ResourcesTableReferences
                                        ._sourceIdTable(db),
                                    referencedColumn: $$ResourcesTableReferences
                                        ._sourceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (resourceTagsRefs)
                        await $_getPrefetchedData<
                          Resource,
                          $ResourcesTable,
                          ResourceTag
                        >(
                          currentTable: table,
                          referencedTable: $$ResourcesTableReferences
                              ._resourceTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ResourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).resourceTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ResourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResourcesTable,
      Resource,
      $$ResourcesTableFilterComposer,
      $$ResourcesTableOrderingComposer,
      $$ResourcesTableAnnotationComposer,
      $$ResourcesTableCreateCompanionBuilder,
      $$ResourcesTableUpdateCompanionBuilder,
      (Resource, $$ResourcesTableReferences),
      Resource,
      PrefetchHooks Function({bool sourceId, bool resourceTagsRefs})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      required String color,
      Value<bool> isBuiltIn,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> color,
      Value<bool> isBuiltIn,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ResourceTagsTable, List<ResourceTag>>
  _resourceTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.resourceTags,
    aliasName: 'tags__id__resource_tags__tag_id',
  );

  $$ResourceTagsTableProcessedTableManager get resourceTagsRefs {
    final manager = $$ResourceTagsTableTableManager(
      $_db,
      $_db.resourceTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_resourceTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> resourceTagsRefs(
    Expression<bool> Function($$ResourceTagsTableFilterComposer f) f,
  ) {
    final $$ResourceTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resourceTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourceTagsTableFilterComposer(
            $db: $db,
            $table: $db.resourceTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> resourceTagsRefs<T extends Object>(
    Expression<T> Function($$ResourceTagsTableAnnotationComposer a) f,
  ) {
    final $$ResourceTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resourceTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourceTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.resourceTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool resourceTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                isBuiltIn: isBuiltIn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String color,
                Value<bool> isBuiltIn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                isBuiltIn: isBuiltIn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({resourceTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (resourceTagsRefs) db.resourceTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (resourceTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, ResourceTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._resourceTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).resourceTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool resourceTagsRefs})
    >;
typedef $$ResourceTagsTableCreateCompanionBuilder =
    ResourceTagsCompanion Function({
      required String resourceId,
      required String tagId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ResourceTagsTableUpdateCompanionBuilder =
    ResourceTagsCompanion Function({
      Value<String> resourceId,
      Value<String> tagId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ResourceTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ResourceTagsTable, ResourceTag> {
  $$ResourceTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ResourcesTable _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias('resource_tags__resource_id__resources__id');

  $$ResourcesTableProcessedTableManager get resourceId {
    final $_column = $_itemColumn<String>('resource_id')!;

    final manager = $$ResourcesTableTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('resource_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ResourceTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ResourceTagsTable> {
  $$ResourceTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ResourcesTableFilterComposer get resourceId {
    final $$ResourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourceTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ResourceTagsTable> {
  $$ResourceTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ResourcesTableOrderingComposer get resourceId {
    final $$ResourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourceTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResourceTagsTable> {
  $$ResourceTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ResourcesTableAnnotationComposer get resourceId {
    final $$ResourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourceTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResourceTagsTable,
          ResourceTag,
          $$ResourceTagsTableFilterComposer,
          $$ResourceTagsTableOrderingComposer,
          $$ResourceTagsTableAnnotationComposer,
          $$ResourceTagsTableCreateCompanionBuilder,
          $$ResourceTagsTableUpdateCompanionBuilder,
          (ResourceTag, $$ResourceTagsTableReferences),
          ResourceTag,
          PrefetchHooks Function({bool resourceId, bool tagId})
        > {
  $$ResourceTagsTableTableManager(_$AppDatabase db, $ResourceTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResourceTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResourceTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResourceTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> resourceId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResourceTagsCompanion(
                resourceId: resourceId,
                tagId: tagId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String resourceId,
                required String tagId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResourceTagsCompanion.insert(
                resourceId: resourceId,
                tagId: tagId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResourceTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resourceId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (resourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resourceId,
                                referencedTable: $$ResourceTagsTableReferences
                                    ._resourceIdTable(db),
                                referencedColumn: $$ResourceTagsTableReferences
                                    ._resourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$ResourceTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$ResourceTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ResourceTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResourceTagsTable,
      ResourceTag,
      $$ResourceTagsTableFilterComposer,
      $$ResourceTagsTableOrderingComposer,
      $$ResourceTagsTableAnnotationComposer,
      $$ResourceTagsTableCreateCompanionBuilder,
      $$ResourceTagsTableUpdateCompanionBuilder,
      (ResourceTag, $$ResourceTagsTableReferences),
      ResourceTag,
      PrefetchHooks Function({bool resourceId, bool tagId})
    >;
typedef $$AppConfigTableCreateCompanionBuilder =
    AppConfigCompanion Function({
      Value<int> id,
      Value<AppThemeMode> themeMode,
      Value<PageDirection> pageDirection,
      Value<DoublePageMode> doublePageMode,
      Value<bool> crossChapter,
      Value<int> cacheLimitMB,
      Value<AutoSyncInterval> autoSyncInterval,
      Value<DateTime> updatedAt,
    });
typedef $$AppConfigTableUpdateCompanionBuilder =
    AppConfigCompanion Function({
      Value<int> id,
      Value<AppThemeMode> themeMode,
      Value<PageDirection> pageDirection,
      Value<DoublePageMode> doublePageMode,
      Value<bool> crossChapter,
      Value<int> cacheLimitMB,
      Value<AutoSyncInterval> autoSyncInterval,
      Value<DateTime> updatedAt,
    });

class $$AppConfigTableFilterComposer
    extends Composer<_$AppDatabase, $AppConfigTable> {
  $$AppConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AppThemeMode, AppThemeMode, String>
  get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PageDirection, PageDirection, String>
  get pageDirection => $composableBuilder(
    column: $table.pageDirection,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DoublePageMode, DoublePageMode, String>
  get doublePageMode => $composableBuilder(
    column: $table.doublePageMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get crossChapter => $composableBuilder(
    column: $table.crossChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheLimitMB => $composableBuilder(
    column: $table.cacheLimitMB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AutoSyncInterval, AutoSyncInterval, String>
  get autoSyncInterval => $composableBuilder(
    column: $table.autoSyncInterval,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $AppConfigTable> {
  $$AppConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageDirection => $composableBuilder(
    column: $table.pageDirection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doublePageMode => $composableBuilder(
    column: $table.doublePageMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get crossChapter => $composableBuilder(
    column: $table.crossChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheLimitMB => $composableBuilder(
    column: $table.cacheLimitMB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get autoSyncInterval => $composableBuilder(
    column: $table.autoSyncInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppConfigTable> {
  $$AppConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AppThemeMode, String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PageDirection, String> get pageDirection =>
      $composableBuilder(
        column: $table.pageDirection,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DoublePageMode, String> get doublePageMode =>
      $composableBuilder(
        column: $table.doublePageMode,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get crossChapter => $composableBuilder(
    column: $table.crossChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheLimitMB => $composableBuilder(
    column: $table.cacheLimitMB,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AutoSyncInterval, String>
  get autoSyncInterval => $composableBuilder(
    column: $table.autoSyncInterval,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppConfigTable,
          AppConfigRow,
          $$AppConfigTableFilterComposer,
          $$AppConfigTableOrderingComposer,
          $$AppConfigTableAnnotationComposer,
          $$AppConfigTableCreateCompanionBuilder,
          $$AppConfigTableUpdateCompanionBuilder,
          (
            AppConfigRow,
            BaseReferences<_$AppDatabase, $AppConfigTable, AppConfigRow>,
          ),
          AppConfigRow,
          PrefetchHooks Function()
        > {
  $$AppConfigTableTableManager(_$AppDatabase db, $AppConfigTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<AppThemeMode> themeMode = const Value.absent(),
                Value<PageDirection> pageDirection = const Value.absent(),
                Value<DoublePageMode> doublePageMode = const Value.absent(),
                Value<bool> crossChapter = const Value.absent(),
                Value<int> cacheLimitMB = const Value.absent(),
                Value<AutoSyncInterval> autoSyncInterval = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppConfigCompanion(
                id: id,
                themeMode: themeMode,
                pageDirection: pageDirection,
                doublePageMode: doublePageMode,
                crossChapter: crossChapter,
                cacheLimitMB: cacheLimitMB,
                autoSyncInterval: autoSyncInterval,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<AppThemeMode> themeMode = const Value.absent(),
                Value<PageDirection> pageDirection = const Value.absent(),
                Value<DoublePageMode> doublePageMode = const Value.absent(),
                Value<bool> crossChapter = const Value.absent(),
                Value<int> cacheLimitMB = const Value.absent(),
                Value<AutoSyncInterval> autoSyncInterval = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppConfigCompanion.insert(
                id: id,
                themeMode: themeMode,
                pageDirection: pageDirection,
                doublePageMode: doublePageMode,
                crossChapter: crossChapter,
                cacheLimitMB: cacheLimitMB,
                autoSyncInterval: autoSyncInterval,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppConfigTable,
      AppConfigRow,
      $$AppConfigTableFilterComposer,
      $$AppConfigTableOrderingComposer,
      $$AppConfigTableAnnotationComposer,
      $$AppConfigTableCreateCompanionBuilder,
      $$AppConfigTableUpdateCompanionBuilder,
      (
        AppConfigRow,
        BaseReferences<_$AppDatabase, $AppConfigTable, AppConfigRow>,
      ),
      AppConfigRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$ResourcesTableTableManager get resources =>
      $$ResourcesTableTableManager(_db, _db.resources);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ResourceTagsTableTableManager get resourceTags =>
      $$ResourceTagsTableTableManager(_db, _db.resourceTags);
  $$AppConfigTableTableManager get appConfig =>
      $$AppConfigTableTableManager(_db, _db.appConfig);
}
