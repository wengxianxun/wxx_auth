import 'package:flutter/widgets.dart';

import '../models/auth_user.dart';

/// 第三方登录方式的统一抽象（可扩展的核心扩展点）。
///
/// 新增一种登录方式（如微信、Facebook、GitHub）只需：
/// 1. 新建一个实现本类的类（如 [GoogleAuth]）；
/// 2. 新建对应的 `XxxAuthConfig` 并在 [WxxAuthConfig] 中注册即可。
///
/// 框架会根据 [id] 在配置中决定是否启用（可选），UI 也会据此动态渲染按钮。
/// 状态管理统一由 GetX 的 [WxxAuthController] 负责，本类只负责"单次登录动作"。
abstract class AuthMethod {
  const AuthMethod();

  /// 唯一标识，例如 `'google'`、`'apple'`。
  String get id;

  /// 展示名称，用于 UI 文案。
  String get displayName;

  /// 当前平台是否支持且已正确配置（可选开关的判断依据）。
  bool get isAvailable;

  /// 发起登录，返回 [AuthUser]；用户取消或失败抛 [AuthException]。
  Future<AuthUser> signIn();

  /// 退出登录（清除本地会话；Apple 无服务端登出，仅清理本地）。
  Future<void> signOut();

  /// 静默恢复已有会话（用于冷启动自动登录）。不支持的实现返回 `null`。
  Future<AuthUser?> getCurrentUser();

  /// 构建该登录方式的按钮。默认由 [WxxAuthView] 调用，
  /// [loading] 为 true 时按钮应展示加载态。
  Widget buildButton({
    required VoidCallback onPressed,
    required bool loading,
  });
}
