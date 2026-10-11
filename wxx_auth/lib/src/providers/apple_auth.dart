import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/auth_method.dart';
import '../models/auth_user.dart';

/// Apple 登录实现（iOS / Android）。
///
/// 注意：`SignInWithAppleButton` 在本版本仅为展示组件，登录逻辑由本类
/// 调用 [SignInWithApple.getAppleIDCredential] 完成，加载态由外层叠加。
class AppleAuth extends AuthMethod {
  const AppleAuth({
    this.scopes = const [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    this.webAuthenticationOptions,
    this.nonce,
  });

  /// 唯一标识，与 [AppleAuthConfig] 对应。
  static const String methodId = 'apple';

  final List<AppleIDAuthorizationScopes> scopes;
  final WebAuthenticationOptions? webAuthenticationOptions;

  /// 可选的 nonce，配合后端防重放攻击。
  final String? nonce;

  @override
  String get id => methodId;

  @override
  String get displayName => 'Apple';

  @override
  bool get isAvailable => true;

  @override
  Future<AuthUser> signIn() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: scopes,
      webAuthenticationOptions: webAuthenticationOptions,
      nonce: nonce,
    );
    final name = <String?>[
      credential.givenName,
      credential.familyName,
    ].where((e) => e != null && e.isNotEmpty).join(' ');
    return AuthUser(
      providerId: id,
      id: credential.userIdentifier,
      email: credential.email,
      displayName: name.isNotEmpty ? name : null,
      identityToken: credential.identityToken,
      authorizationCode: credential.authorizationCode,
      raw: <String, dynamic>{
        'userIdentifier': credential.userIdentifier,
        'email': credential.email,
        'givenName': credential.givenName,
        'familyName': credential.familyName,
        'authorizationCode': credential.authorizationCode,
        'identityToken': credential.identityToken,
      },
    );
  }

  @override
  Future<void> signOut() async {
    // Apple 不提供程序化登出，仅清理本地状态（由 controller 处理）。
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    // Apple 无法在无需 UI 交互的情况下静默恢复，返回 null。
    return null;
  }

  @override
  Widget buildButton({
    required VoidCallback onPressed,
    required bool loading,
  }) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SignInWithAppleButton(
            onPressed: loading ? null : onPressed,
            text: '使用 Apple 登录',
            height: 50,
            style: SignInWithAppleButtonStyle.black,
          ),
          if (loading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
