import 'package:flutter/widgets.dart';
import 'package:flutter_taptap/flutter_taptap.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/auth_method.dart';
import '../models/taptap_compliance.dart';
import '../providers/apple_auth.dart';
import '../providers/google_auth.dart';
import '../providers/taptap_auth.dart';

/// 每种登录方式的配置基类。实现类负责 [build] 出对应的 [AuthMethod]。
abstract class AuthMethodConfig {
  String get methodId;
  AuthMethod build();
}

/// Google 登录配置（可选、可扩展：不加到 [WxxAuthConfig.methods] 即不启用）。
class GoogleAuthConfig implements AuthMethodConfig {
  const GoogleAuthConfig({
    this.clientId,
    this.serverClientId,
    this.scopes = const ['email', 'profile'],
    this.hostedDomain,
  });

  /// Web / Desktop 端 OAuth clientId（移动端一般留空，由平台配置提供）。
  final String? clientId;

  /// 用于后端校验的 serverClientId（可选）。
  final String? serverClientId;

  final List<String> scopes;
  final String? hostedDomain;

  @override
  String get methodId => GoogleAuth.methodId;

  @override
  AuthMethod build() => GoogleAuth(
        clientId: clientId,
        serverClientId: serverClientId,
        scopes: scopes,
        hostedDomain: hostedDomain,
      );
}

/// Apple 登录配置。
///
/// 注意：在 Android 上 Apple 登录会回退到网页流程，
/// 必须提供 [webAuthenticationOptions]（clientId 与 redirectUri）。
class AppleAuthConfig implements AuthMethodConfig {
  const AppleAuthConfig({
    this.scopes = const [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    this.webAuthenticationOptions,
    this.nonce,
  });

  final List<AppleIDAuthorizationScopes> scopes;
  final WebAuthenticationOptions? webAuthenticationOptions;

  /// 可选的 nonce，配合后端防重放攻击。
  final String? nonce;

  @override
  String get methodId => AppleAuth.methodId;

  @override
  AuthMethod build() => AppleAuth(
        scopes: scopes,
        webAuthenticationOptions: webAuthenticationOptions,
        nonce: nonce,
      );
}

/// TapTap 登录配置。
///
/// 必填 [clientId] / [clientToken]（来自 TapTap 开发者中心）。
/// [enableAntiAddiction] 控制登录后是否做防沉迷校验，默认关闭——
/// 关闭时适合不需要该合规的平台，开启后请实现 [onComplianceResult] 处理合规结果。
class TaptapAuthConfig implements AuthMethodConfig {
  const TaptapAuthConfig({
    required this.clientId,
    required this.clientToken,
    this.region = TapTapRegion.cn,
    this.screenOrientation = 1,
    this.enableLog = false,
    this.scopes = const ['public_profile'],
    this.enableAntiAddiction = false,
    this.onComplianceResult,
  });

  final String clientId;
  final String clientToken;

  /// 服务器区域，默认中国区。
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

  @override
  String get methodId => TaptapAuth.methodId;

  @override
  AuthMethod build() => TaptapAuth(
        clientId: clientId,
        clientToken: clientToken,
        region: region,
        screenOrientation: screenOrientation,
        enableLog: enableLog,
        scopes: scopes,
        enableAntiAddiction: enableAntiAddiction,
        onComplianceResult: onComplianceResult,
      );
}

/// 登录视图的 UI 配置。
class WxxAuthUiConfig {
  const WxxAuthUiConfig({
    this.title,
    this.subtitle,
    this.buttonSpacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.showErrors = true,
  });

  final String? title;
  final String? subtitle;
  final double buttonSpacing;
  final EdgeInsetsGeometry padding;
  final bool showErrors;

  WxxAuthUiConfig copyWith({
    String? title,
    String? subtitle,
    double? buttonSpacing,
    EdgeInsetsGeometry? padding,
    bool? showErrors,
  }) {
    return WxxAuthUiConfig(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      padding: padding ?? this.padding,
      showErrors: showErrors ?? this.showErrors,
    );
  }
}

/// 统一初始化配置：声明要启用的登录方式（可选）、UI 样式与是否自动恢复会话。
class WxxAuthConfig {
  const WxxAuthConfig({
    required this.methods,
    this.ui = const WxxAuthUiConfig(),
    this.autoRestore = true,
  });

  /// 要启用的登录方式列表。只放入需要的即可（可选、可扩展）。
  final List<AuthMethodConfig> methods;

  /// UI 配置。
  final WxxAuthUiConfig ui;

  /// 是否尝试静默恢复已有会话（冷启动自动登录）。
  final bool autoRestore;

  List<AuthMethod> buildMethods() => methods.map((c) => c.build()).toList();

  /// 快捷构造：同时启用 Google 与 Apple。
  static WxxAuthConfig googleAndApple({
    String? googleClientId,
    String? googleServerClientId,
    List<String> googleScopes = const ['email', 'profile'],
    List<AppleIDAuthorizationScopes> appleScopes = const [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    WebAuthenticationOptions? appleWebOptions,
    WxxAuthUiConfig ui = const WxxAuthUiConfig(),
    bool autoRestore = true,
  }) {
    return WxxAuthConfig(
      methods: <AuthMethodConfig>[
        GoogleAuthConfig(
          clientId: googleClientId,
          serverClientId: googleServerClientId,
          scopes: googleScopes,
        ),
        AppleAuthConfig(
          scopes: appleScopes,
          webAuthenticationOptions: appleWebOptions,
        ),
      ],
      ui: ui,
      autoRestore: autoRestore,
    );
  }

  /// 快捷构造：同时启用 Google、Apple 与 TapTap。
  static WxxAuthConfig googleAppleTapTap({
    String? googleClientId,
    String? googleServerClientId,
    List<String> googleScopes = const ['email', 'profile'],
    List<AppleIDAuthorizationScopes> appleScopes = const [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    WebAuthenticationOptions? appleWebOptions,
    required String taptapClientId,
    required String taptapClientToken,
    bool taptapEnableAntiAddiction = false,
    void Function(TaptapComplianceResult)? taptapOnComplianceResult,
    WxxAuthUiConfig ui = const WxxAuthUiConfig(),
    bool autoRestore = true,
  }) {
    return WxxAuthConfig(
      methods: <AuthMethodConfig>[
        GoogleAuthConfig(
          clientId: googleClientId,
          serverClientId: googleServerClientId,
          scopes: googleScopes,
        ),
        AppleAuthConfig(
          scopes: appleScopes,
          webAuthenticationOptions: appleWebOptions,
        ),
        TaptapAuthConfig(
          clientId: taptapClientId,
          clientToken: taptapClientToken,
          enableAntiAddiction: taptapEnableAntiAddiction,
          onComplianceResult: taptapOnComplianceResult,
        ),
      ],
      ui: ui,
      autoRestore: autoRestore,
    );
  }
}
