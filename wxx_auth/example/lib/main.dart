import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_auth/wxx_auth.dart';

import 'backend/api_client.dart';
import 'backend/auth_repository.dart';
import 'backend/backend_controller.dart';

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
        // Apple：iOS 走系统原生弹窗，无需后端 / redirectUri，留空即可。
        // （若日后要测 Android，再补 webAuthenticationOptions。）
        const AppleAuthConfig(),
        // TapTap：必填 clientId / clientToken（来自 TapTap 开发者中心）。
        // enableAntiAddiction 默认 false：关闭时登录后不触发防沉迷，
        // 适合不需要该合规的平台；需要时在下方设为 true 并实现 onComplianceResult。
        const TaptapAuthConfig(
          clientId: 'r1lmyehm3henfhcusx',
          clientToken: 'q3vWCHAHCjL9vmG2hWSCwXLQQb2VHo1FTy3Yq2fe',
          enableAntiAddiction: false,
        ),
      ],
      ui: const WxxAuthUiConfig(title: '欢迎使用', subtitle: '请选择登录方式继续'),
      autoRestore: true,
    ),
  );

  // 2) 后端接入：初始化 API 客户端、业务仓储与示例控制器（监听插件登录态）。
  final api = ApiClient();
  final repo = AuthRepository(api);
  Get.put(BackendController(repo));

  runApp(const MyApp());
}

/// 圆形头像：有 URL 时加载网络图，无图或加载失败时显示首字母占位。
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String? name;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final letter = (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?';
    final hasUrl = url?.isNotEmpty == true;
    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child: hasUrl
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(letter),
              )
            : _placeholder(letter),
      ),
    );
  }

  Widget _placeholder(String letter) => Container(
    color: Colors.blueGrey.shade200,
    alignment: Alignment.center,
    child: Text(
      letter,
      style: const TextStyle(
        fontSize: 26,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
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
  Widget build(BuildContext context) {
    final backend = Get.find<BackendController>();
    return Scaffold(
      appBar: AppBar(title: const Text('wxx_auth 示例')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(10),

                child: const WxxAuthView(),
              ),

              const SizedBox(height: 32),
              // 3) 插件登录状态。
              Obx(() {
                final user = WxxAuth.controller.user.value;
                if (user == null) {
                  return const Text('尚未登录', textAlign: TextAlign.center);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: <Widget>[
                    _Avatar(url: user.photoUrl, name: user.displayName),
                    const SizedBox(height: 8),
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
                    Text(
                      '邮箱：${user.email ?? '-'}',
                      textAlign: TextAlign.center,
                    ),
                    if (user.idToken != null)
                      Text(
                        'idToken：${user.idToken!.substring(0, 24)}…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    // 若使用 TapTap 且开启了防沉迷，这里展示校验结果。
                    Builder(
                      builder: (context) {
                        final c = WxxAuth.controller.compliance.value;
                        if (c == null) return const SizedBox.shrink();
                        final time =
                            c.remainingTime != null && c.remainingTime! >= 0
                            ? '，剩余 ${c.remainingTime} 秒'
                            : '';
                        return Text(
                          '防沉迷：${c.canPlay ? '通过（可正常游戏）' : '受限（${c.status}）'}$time',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.canPlay ? Colors.green : Colors.orange,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => WxxAuth.controller.signOut(),
                      child: const Text('退出登录'),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      '后端校验结果',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BackendPanel(backend: backend),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// 后端校验结果展示面板。
class _BackendPanel extends StatelessWidget {
  const _BackendPanel({required this.backend});

  final BackendController backend;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final widgets = <Widget>[
        // 后端自检（无需登录，用于确认模块路由与配置已加载）。
        ElevatedButton(
          onPressed: backend.isPinging.value ? null : backend.ping,
          child: backend.isPinging.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('检查后端连通性 (ping)'),
        ),
        const SizedBox(height: 8),
        if (backend.pingError.value.isNotEmpty)
          Text(
            '⚠️ ${backend.pingError.value}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.orange),
          )
        else if (backend.pingResult.value != null)
          Text(
            '后端就绪：${backend.pingResult.value!.ok ? '是' : '否'}'
            '，已配置方式：${backend.pingResult.value!.providers.join(' / ')}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.green),
          ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
      ];

      if (backend.isSigningInBackend.value) {
        widgets.add(const Center(child: CircularProgressIndicator()));
      } else if (backend.backendError.value.isNotEmpty) {
        widgets.add(
          Text(
            '⚠️ ${backend.backendError.value}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.orange),
          ),
        );
      } else {
        final res = backend.signInResult.value;
        if (res == null) {
          widgets.add(
            const Text(
              '等待登录后向后端校验…',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        } else {
          widgets.addAll(<Widget>[
            const SizedBox(height: 8),
            Text('后端 UUID：${res.user.uuid}', textAlign: TextAlign.center),
            Text('是否新用户：${res.isNew ? '是' : '否'}', textAlign: TextAlign.center),
            Text('邮箱：${res.user.email ?? '-'}', textAlign: TextAlign.center),
            Text(
              '名称：${res.user.displayName ?? '-'}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: backend.isLoadingProfile.value
                  ? null
                  : backend.loadProfile,
              child: backend.isLoadingProfile.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('获取用户信息 / 已绑平台'),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final p = backend.profile.value;
              if (p == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Text(
                    '名称：${p.user.displayName ?? '-'}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '已绑定的登录方式：',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...p.providers.map(
                    (pr) => Text(
                      '· ${pr.provider}（${pr.providerUserId}）',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }),
          ]);
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widgets,
      );
    });
  }
}
