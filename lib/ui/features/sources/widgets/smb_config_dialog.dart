import 'package:flutter/material.dart';

import '../../../../domain/core/result.dart';

typedef SmbConnectionTester =
    Future<Result<bool>> Function({
      required String host,
      required String share,
      int port,
      String? username,
      String? password,
      String? domain,
    });

/// SMB 配置对话框
///
/// 用于添加或编辑 SMB 数据源的配置。
class SmbConfigDialog extends StatefulWidget {
  const SmbConfigDialog({
    super.key,
    this.initialName,
    this.initialHost,
    this.initialShare,
    this.initialPort = 445,
    this.initialUsername,
    this.initialDomain,
    this.isEditMode = false,
    required this.onTestConnection,
  });

  /// 初始源名称（编辑模式）
  final String? initialName;

  /// 初始主机地址
  final String? initialHost;

  /// 初始共享名称
  final String? initialShare;

  /// 初始端口
  final int initialPort;

  /// 初始用户名
  final String? initialUsername;

  /// 初始域
  final String? initialDomain;

  /// 是否为编辑模式
  final bool isEditMode;

  final SmbConnectionTester onTestConnection;

  /// 显示 SMB 配置对话框
  static Future<SmbConfigResult?> show(
    BuildContext context, {
    String? initialName,
    String? initialHost,
    String? initialShare,
    int initialPort = 445,
    String? initialUsername,
    String? initialDomain,
    bool isEditMode = false,
    required SmbConnectionTester onTestConnection,
  }) {
    return showDialog<SmbConfigResult>(
      context: context,
      builder: (context) => SmbConfigDialog(
        initialName: initialName,
        initialHost: initialHost,
        initialShare: initialShare,
        initialPort: initialPort,
        initialUsername: initialUsername,
        initialDomain: initialDomain,
        isEditMode: isEditMode,
        onTestConnection: onTestConnection,
      ),
    );
  }

  @override
  State<SmbConfigDialog> createState() => _SmbConfigDialogState();
}

class _SmbConfigDialogState extends State<SmbConfigDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _shareController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _domainController;

  bool _isTesting = false;
  bool _testSuccess = false;
  String? _testError;
  int _formRevision = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _hostController = TextEditingController(text: widget.initialHost);
    _shareController = TextEditingController(text: widget.initialShare);
    _portController = TextEditingController(
      text: widget.initialPort.toString(),
    );
    _usernameController = TextEditingController(text: widget.initialUsername);
    _passwordController = TextEditingController();
    _domainController = TextEditingController(text: widget.initialDomain);
    for (final controller in [
      _nameController,
      _hostController,
      _shareController,
      _portController,
      _usernameController,
      _passwordController,
      _domainController,
    ]) {
      controller.addListener(_invalidateTestResult);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _shareController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditMode ? '编辑 SMB 凭据' : '添加 SMB 网络共享'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.isEditMode) ...[
                  _buildNameField(),
                  const SizedBox(height: 16),
                ],
                _buildHostField(),
                const SizedBox(height: 16),
                _buildShareField(),
                const SizedBox(height: 16),
                _buildPortField(),
                const SizedBox(height: 16),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildDomainField(),
                const SizedBox(height: 24),
                _buildTestButton(),
                if (_testError != null) ...[
                  const SizedBox(height: 8),
                  _buildTestError(),
                ],
                if (_testSuccess) ...[
                  const SizedBox(height: 8),
                  _buildTestSuccess(),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _testSuccess ? _onSubmit : null,
          child: Text(widget.isEditMode ? '保存' : '添加'),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '源名称 *',
        hintText: '例如：家庭 NAS',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入源名称';
        }
        return null;
      },
    );
  }

  Widget _buildHostField() {
    return TextFormField(
      controller: _hostController,
      readOnly: widget.isEditMode,
      decoration: const InputDecoration(
        labelText: 'SMB 地址 *',
        hintText: '例如：192.168.1.100 或 nas.local',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入 SMB 地址';
        }
        return null;
      },
    );
  }

  Widget _buildShareField() {
    return TextFormField(
      controller: _shareController,
      readOnly: widget.isEditMode,
      decoration: const InputDecoration(
        labelText: '共享名称 *',
        hintText: '例如：Documents 或 Media',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入共享名称';
        }
        return null;
      },
    );
  }

  Widget _buildPortField() {
    return TextFormField(
      controller: _portController,
      readOnly: widget.isEditMode,
      decoration: const InputDecoration(
        labelText: '端口',
        hintText: '默认 445',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final port = int.tryParse(value);
          if (port == null || port < 1 || port > 65535) {
            return '端口范围：1-65535';
          }
          if (port != 445) {
            return '当前 SMB 组件仅支持端口 445';
          }
        }
        return null;
      },
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: '用户名',
        hintText: '留空使用访客账户',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: widget.isEditMode ? '新密码（留空保持不变）' : '密码',
        hintText: widget.isEditMode ? '••••••' : '留空使用访客账户',
        border: const OutlineInputBorder(),
      ),
      obscureText: true,
      validator: (value) {
        if (widget.isEditMode && (value == null || value.isEmpty)) {
          return '请输入新密码';
        }
        return null;
      },
    );
  }

  Widget _buildDomainField() {
    return TextFormField(
      controller: _domainController,
      decoration: const InputDecoration(
        labelText: '域/工作组',
        hintText: '可选',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: _isTesting ? null : _onTestConnection,
        icon: _isTesting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.wifi_find),
        label: Text(_isTesting ? '测试中...' : '测试连接'),
      ),
    );
  }

  Widget _buildTestError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _testError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSuccess() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '连接成功',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTestConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testSuccess = false;
      _testError = null;
    });

    final revision = _formRevision;
    final result = await widget.onTestConnection(
      host: _hostController.text.trim(),
      share: _shareController.text.trim(),
      port: int.tryParse(_portController.text) ?? 445,
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
      domain: _domainController.text.trim().isEmpty
          ? null
          : _domainController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      if (revision != _formRevision) return;
      switch (result) {
        case Ok(:final value):
          _testSuccess = value;
          if (!value) _testError = '连接失败，请检查地址和凭据';
        case Err(:final error):
          _testError = _mapDomainError(error);
      }
    });
  }

  String _mapDomainError(DomainError error) {
    return switch (error) {
      SourceAuthError() => '认证失败，请检查用户名和密码',
      NetworkTimeoutError() => '连接超时，请检查地址和端口',
      FileNotFoundError() => '共享路径不存在',
      SourceUnreachableError() => '无法连接到服务器',
      _ => error.message,
    };
  }

  void _invalidateTestResult() {
    _formRevision++;
    if (!mounted || (!_testSuccess && _testError == null)) return;
    setState(() {
      _testSuccess = false;
      _testError = null;
    });
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final result = SmbConfigResult(
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      share: _shareController.text.trim(),
      port: int.tryParse(_portController.text) ?? 445,
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
      domain: _domainController.text.trim().isEmpty
          ? null
          : _domainController.text.trim(),
    );

    Navigator.pop(context, result);
  }
}

/// SMB 配置结果
class SmbConfigResult {
  const SmbConfigResult({
    required this.name,
    required this.host,
    required this.share,
    this.port = 445,
    this.username,
    this.password,
    this.domain,
  });

  final String name;
  final String host;
  final String share;
  final int port;
  final String? username;
  final String? password;
  final String? domain;
}
