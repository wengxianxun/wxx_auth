import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/auth_method.dart';
import '../models/auth_user.dart';
import '../ui/wxx_auth_button.dart';

/// Google 登录实现（仅 iOS / Android）。
///
/// 基于 `google_sign_in` 7.x 单例 API：`initialize()` 预热，
/// `authenticate()` 拉起系统/谷歌授权页，`attemptLightweightAuthentication()`
/// 用于冷启动静默恢复。
class GoogleAuth extends AuthMethod {
  const GoogleAuth({
    this.clientId,
    this.serverClientId,
    this.scopes = const ['email', 'profile'],
    this.hostedDomain,
  });

  /// 唯一标识，与 [GoogleAuthConfig] 对应。
  static const String methodId = 'google';

  /// Web / Desktop 端 OAuth clientId（移动端一般留空，由平台配置提供）。
  final String? clientId;

  /// 用于后端校验的 serverClientId（可选）。
  final String? serverClientId;

  final List<String> scopes;
  final String? hostedDomain;

  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  /// 幂等预热：只初始化一次，多个并发调用共享同一个 Future。
  Future<void> ensureInitialized() async {
    if (_initialized) {
      await _initCompleter?.future;
      return;
    }
    final completer = Completer<void>();
    _initCompleter = completer;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
        hostedDomain: hostedDomain,
      );
      _initialized = true;
      completer.complete();
    } catch (e) {
      _initCompleter = null;
      completer.completeError(e);
      rethrow;
    }
  }

  @override
  String get id => methodId;

  @override
  String get displayName => 'Google';

  @override
  bool get isAvailable => true;

  AuthUser _toUser(GoogleSignInAccount account, GoogleSignInAuthentication auth) {
    return AuthUser(
      providerId: id,
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      idToken: auth.idToken,
      raw: <String, dynamic>{
        'id': account.id,
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
      },
    );
  }

  @override
  Future<AuthUser> signIn() async {
    await ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      return _toUser(account, auth);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthException('已取消 Google 登录', 'cancelled');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // 忽略本地登出异常
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    await ensureInitialized();
    final future = GoogleSignIn.instance.attemptLightweightAuthentication();
    if (future == null) return null;
    final account = await future;
    if (account == null) return null;
    final auth = account.authentication;
    return _toUser(account, auth);
  }

  @override
  Widget buildButton({
    required VoidCallback onPressed,
    required bool loading,
  }) {
    return WxxAuthButton(
      label: '使用 Google 登录',
      onPressed: onPressed,
      loading: loading,
      icon: const _GoogleIcon(),
      style: const WxxAuthButtonStyle(
        backgroundColor: Colors.white,
        textColor: Color(0xFF1F1F1F),
        borderColor: Color(0xFFDADCE0),
      ),
    );
  }
}

/// Google 官方四色 "G" 图标。
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_svg, width: 22, height: 22);
}
