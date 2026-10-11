import 'package:flutter/widgets.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/auth_method.dart';
import '../providers/apple_auth.dart';
import '../providers/google_auth.dart';

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
}
