import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_taptap/flutter_taptap.dart';

import '../core/auth_method.dart';
import '../models/auth_user.dart';
import '../models/taptap_compliance.dart';
import '../ui/wxx_auth_button.dart';

/// TapTap 登录实现（iOS / Android）。
///
/// 基于 `flutter_taptap`：
/// - [initialize] 预热 SDK（clientId / clientToken / region）；
/// - [signIn] 调 `login()` 拿 [TapTapUser] 并转成 [AuthUser]；
/// - 若开启 [enableAntiAddiction]，登录完成后自动跑一次防沉迷校验
///   （[registerComplianceCallback] + [startCompliance]），并把结果通过
///   [onComplianceResult] 回调与 [lastCompliance] 暴露出去。
///
/// 防沉迷为**可选**：未开启时登录后不触发任何合规流程，适合不需要该合规的平台。
class TaptapAuth extends AuthMethod {
  TaptapAuth({
    required this.clientId,
    required this.clientToken,
    this.region = TapTapRegion.cn,
    this.screenOrientation = 1,
    this.enableLog = false,
    this.scopes = const ['public_profile'],
    this.enableAntiAddiction = false,
    this.onComplianceResult,
  });

  /// 唯一标识，与 [TaptapAuthConfig] 对应。
  static const String methodId = 'taptap';

  final String clientId;
  final String clientToken;

  /// 服务器区域，默认中国区（[TapTapRegion.cn]）。
  final TapTapRegion region;

  /// 屏幕方向：0-自动，1-竖屏，2-横屏。
  final int screenOrientation;

  /// 是否开启 SDK 日志。
  final bool enableLog;

  final List<String> scopes;

  /// 是否启用防沉迷（实名 / 未成年人保护）校验。可选，默认关闭。
  final bool enableAntiAddiction;

  /// 防沉迷校验完成后的回调（无论通过与否都会触发）。
  final void Function(TaptapComplianceResult)? onComplianceResult;

  /// 最近一次防沉迷校验结果（未开启或尚未校验为 null）。
  TaptapComplianceResult? lastCompliance;

  static bool _initialized = false;

  /// 幂等预热 SDK（全局单例，只初始化一次）。
  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await FlutterTaptap().init(
      clientId: clientId,
      clientToken: clientToken,
      region: region,
      screenOrientation: screenOrientation,
      enableLog: enableLog,
    );
    _initialized = true;
  }

  @override
  String get id => methodId;

  @override
  String get displayName => 'TapTap';

  @override
  bool get isAvailable => true;

  AuthUser _toUser(TapTapUser user) => AuthUser(
        providerId: id,
        id: user.openId,
        displayName: user.name,
        photoUrl: user.avatar,
        accessToken: user.accessToken,
        raw: user.toMap(),
      );

  @override
  Future<AuthUser> signIn() async {
    await initialize();
    final TapTapUser? user = await FlutterTaptap().login(scopes: scopes);
    if (user == null) {
      throw const AuthException('已取消 TapTap 登录', 'cancelled');
    }
    final authUser = _toUser(user);
    if (enableAntiAddiction) {
      lastCompliance = await _runCompliance(user.openId);
      onComplianceResult?.call(lastCompliance!);
    }
    return authUser;
  }

  /// 执行一次防沉迷校验：注册回调 → 启动校验 → 等待首个回调结果（含超时）。
  Future<TaptapComplianceResult> _runCompliance(String userId) async {
    final completer = Completer<TaptapComplianceResult>();
    await FlutterTaptap().registerComplianceCallback(
      onResult: (event) {
        final code = (event['code'] as int?) ?? -1;
        final status = TaptapComplianceResult.fromCode(code);
        if (!completer.isCompleted) {
          completer.complete(
            TaptapComplianceResult(status: status, code: code),
          );
        }
      },
    );

    try {
      await FlutterTaptap().startCompliance(userId: userId);
    } catch (e) {
      await FlutterTaptap().unregisterComplianceCallback();
      return TaptapComplianceResult(
        status: TaptapComplianceStatus.networkError,
        code: -1,
        message: e.toString(),
      );
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => const TaptapComplianceResult(
        status: TaptapComplianceStatus.networkError,
        code: -1,
        message: '防沉迷认证超时',
      ),
    );
    await FlutterTaptap().unregisterComplianceCallback();

    // 校验通过时顺带拉取剩余可玩时长。
    if (result.status == TaptapComplianceStatus.success) {
      try {
        final remaining = await FlutterTaptap().getRemainingTime();
        return TaptapComplianceResult(
          status: result.status,
          code: result.code,
          remainingTime: remaining,
        );
      } catch (_) {
        // 忽略取剩余时长失败，仍以 success 返回。
      }
    }
    return result;
  }

  @override
  Future<void> signOut() async {
    await FlutterTaptap().logout();
    lastCompliance = null;
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final TapTapUser? user = await FlutterTaptap().getCurrentUser();
    if (user == null) return null;
    return _toUser(user);
  }

  @override
  Widget buildButton({
    required VoidCallback onPressed,
    required bool loading,
  }) {
    return WxxAuthButton(
      label: '使用 TapTap 登录',
      onPressed: onPressed,
      loading: loading,
      icon: const _TaptapIcon(),
      style: const WxxAuthButtonStyle(
        backgroundColor: Color(0xFFF72C5B), // TapTap 品牌粉
        textColor: Colors.white,
        borderRadius: 8,
      ),
    );
  }
}

/// TapTap 简化图标（两个白色气泡，呼应 "tap tap"）。
/// 如需官方 logo，可替换为图片资源。
class _TaptapIcon extends StatelessWidget {
  const _TaptapIcon();

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#FFFFFF" d="M14 9c-5.5 0-10 4-10 9 0 2.6 1.3 4.9 3.4 6.5L6 33l6.4-3.2c1.6.5 3.4.8 5.2.8 5.5 0 10-4 10-9s-4.5-9-10-9z"/>
  <path fill="#FFFFFF" fill-opacity="0.82" d="M34 19c-4.4 0-8 3.1-8 7 0 2.1 1 3.9 2.7 5.2L27 37l5-2.5c1.3.4 2.7.6 4.2.6 4.4 0 8-3.1 8-7s-3.6-7-8-7z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_svg, width: 22, height: 22);
}
