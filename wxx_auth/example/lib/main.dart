import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wxx_auth/wxx_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 统一初始化：声明要启用的登录方式（可选、可扩展）。
  await WxxAuth.init(
    WxxAuthConfig(
      methods: <AuthMethodConfig>[
        // Google：移动端一般无需 clientId，仅需后端校验时填 serverClientId。
        const GoogleAuthConfig(
          serverClientId: '496718607957-9k4hmg1p9fora5ivaai7hl8mc3ch1i5b.apps.googleusercontent.com',
        ),
        // Apple：Android 走网页回退流程，必须提供 webAuthenticationOptions。
        // AppleAuthConfig(
        //   webAuthenticationOptions: WebAuthenticationOptions(
        //     clientId: 'com.example.wxxAuthExample',
        //     redirectUri: Uri.parse(
        //       'https://your-backend.example.com/callbacks/sign_in_with_apple',
        //     ),
        //   ),
        // ),
      ],
      ui: const WxxAuthUiConfig(title: '欢迎使用', subtitle: '请选择登录方式继续'),
      autoRestore: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'wxx_auth 示例',
    theme: ThemeData(useMaterial3: true),
    home: const LoginPage(),
  );
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('wxx_auth 示例')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const WxxAuthView(),
          const SizedBox(height: 32),
          // 2) 通过 GetX 控制器读取登录状态。
          Obx(() {
            final user = WxxAuth.controller.user.value;
            if (user == null) {
              return const Text('尚未登录', textAlign: TextAlign.center);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '已登录（${user.providerId}）',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '名称：${user.displayName ?? '-'}',
                  textAlign: TextAlign.center,
                ),
                Text('邮箱：${user.email ?? '-'}', textAlign: TextAlign.center),
                if (user.idToken != null)
                  Text(
                    'idToken：${user.idToken!.substring(0, 24)}…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => WxxAuth.controller.signOut(),
                  child: const Text('退出登录'),
                ),
              ],
            );
          }),
        ],
      ),
    ),
  );
}
