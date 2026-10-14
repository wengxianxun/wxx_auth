# wxx_auth

第三方登录整合插件（iOS / Android）。第一版内置 **Google 登录**、**Apple 登录** 与 **TapTap 登录**，并采用**可扩展、可选、统一配置**的架构，状态管理基于 **GetX**。TapTap 登录后支持**可选**的防沉迷（实名 / 未成年人保护）校验，按需开启。

## 特性

- 🔌 **可扩展**：每种登录方式是一个实现 `AuthMethod` 的类，新增微信 / Facebook / GitHub 只需加一个类 + 配置类。
- ☑️ **可选**：在 `Wxx_authConfig.methods` 里放哪些，就启用哪些，UI 自动只渲染已配置的方式。
- 🧩 **统一初始化**：一次 `WxxAuth.init(config)` 完成所有配置。
- 🧠 **GetX 状态管理**：登录用户、加载态、错误统一由 `WxxAuthController` 管理，UI 用 `Obx` 响应式刷新。
- 📱 **iOS / Android**：基于 `google_sign_in ^7.2.0`、`sign_in_with_apple ^8.2.0` 与 `flutter_taptap`（TapTap）。
- 🛡️ **可选防沉迷**：TapTap 登录后可开启防沉迷校验（`enableAntiAddiction`），不适合的平台关闭即可，不影响其它登录方式。

## 安装

```yaml
dependencies:
  wxx_auth: ^0.0.1
  get: ^4.7.2
```

并在 `main()` 中初始化（见下方）。

## 快速开始

### 1. 统一初始化

```dart
import 'package:wxx_auth/wxx_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await WxxAuth.init(
    WxxAuthConfig(
      methods: [
        const GoogleAuthConfig(
          serverClientId: 'YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com',
        ),
        AppleAuthConfig(
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.example.yourapp',
            redirectUri: Uri.parse('https://your-backend/callbacks/sign_in_with_apple'),
          ),
        ),
      ],
      ui: const WxxAuthUiConfig(title: '欢迎', subtitle: '请选择登录方式'),
      autoRestore: true,
    ),
  );

  runApp(const MyApp());
}
```

> 也可以直接用快捷构造：`WxxAuthConfig.googleAndApple(...)`（Google + Apple），或 `WxxAuthConfig.googleAppleTapTap(...)`（三者全开，需传入 TapTap 的 clientId / clientToken）。

#### 加入 TapTap 登录

```dart
await WxxAuth.init(
  WxxAuthConfig(
    methods: <AuthMethodConfig>[
      const GoogleAuthConfig(serverClientId: 'YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com'),
      const AppleAuthConfig(),
      // TapTap 必填 clientId / clientToken（来自 TapTap 开发者中心）。
      TaptapAuthConfig(
        clientId: 'YOUR_TAPTAP_CLIENT_ID',
        clientToken: 'YOUR_TAPTAP_CLIENT_TOKEN',
        // 可选：开启防沉迷校验（默认关闭）。
        enableAntiAddiction: true,
        onComplianceResult: (result) {
          // result.status / result.canPlay / result.remainingTime
          if (!result.canPlay) {
            // 受限：返回登录页或阻断游戏
          }
        },
      ),
    ],
    ui: const WxxAuthUiConfig(title: '欢迎', subtitle: '请选择登录方式'),
  ),
);
```

### 2.1 TapTap 防沉迷（可选）

TapTap 登录后若开启 `enableAntiAddiction`，插件会自动跑一次防沉迷校验（注册回调 + `startCompliance`），并把结果通过：

- 回调 `onComplianceResult(TaptapComplianceResult)`；
- 控制器可观察值 `WxxAuth.controller.compliance`（在 `signInWith` 完成后填充）。

`TaptapComplianceResult` 关键字段：

| 字段 | 说明 |
| --- | --- |
| `status` | 合规状态枚举（`success` / `exited` / `switchAccount` / `periodRestrict` / `durationLimit` / `ageLimit` / `networkError` / `realNameStop` / `unknown`） |
| `canPlay` | 是否允许继续游戏（仅 `success` 为 true） |
| `isRestricted` | 是否受限（需返回登录页或阻断） |
| `remainingTime` | 剩余可玩秒数；`-1` 未登录/未初始化，`-2` 不受限（如成年人） |

> 防沉迷为**可选开关**，默认关闭。关闭时 TapTap 登录后不触发任何合规流程，适合不需要该合规的平台（如部分海外发行）。

### 2. 放置登录界面

```dart
import 'package:get/get.dart';
import 'package:wxx_auth/wxx_auth.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const WxxAuthView(),
            Obx(() {
              final user = WxxAuth.controller.user.value;
              if (user == null) return const Text('未登录');
              return Text('已登录：${user.displayName ?? user.email}');
            }),
          ],
        ),
      ),
    );
  }
}
```

宿主应用请使用 `GetMaterialApp`（或确保 GetX 已初始化）。

### 3. 读取状态 / 登出

```dart
// 当前用户
WxxAuth.controller.user.value;

// 指定方式登录（如按钮已自动处理，一般无需手动调用）
await WxxAuth.controller.signInWith('google');

// 登出
await WxxAuth.controller.signOut();
```

## 登录结果 `AuthUser`

| 字段 | 说明 |
| --- | --- |
| `providerId` | 来源，如 `'google'` / `'apple'` |
| `id` | 第三方平台用户唯一标识 |
| `email` / `displayName` / `photoUrl` | 用户资料 |
| `idToken` | Google 的 JWT id_token |
| `identityToken` | Apple 的 identityToken（JWT） |
| `authorizationCode` | Apple 授权码（需发后端校验） |

## 平台原生配置（必做）

- **Google**：在 `android/app/src/main/AndroidManifest.xml` 配置 `webClientId` 等，并在 iOS 的 `Info.plist` 配置 `GIDClientID`（或 `GoogleService-Info.plist`）。详见 [google_sign_in](https://pub.dev/packages/google_sign_in)。
- **Apple**：iOS 需在 Developer Portal 开启 **Sign in with Apple** 能力；Android 回退到网页流程，必须提供 `webAuthenticationOptions`（clientId + redirectUri）。详见 [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple)。
- **TapTap**：在 [TapTap 开发者中心](https://developer.taptap.cn/) 创建应用获取 `clientId` / `clientToken`。
  - Android：在 `android/app/build.gradle` 的 `defaultConfig` 加 `manifestPlaceholders += ['taptapClientId': 'your_client_id']`。
  - iOS：在 `ios/Runner/Info.plist` 配置 `CFBundleURLTypes`，scheme 为 `tt{your_client_id}`。
  - 详见 `flutter_taptap` 包的 README。开启防沉迷需确保 SDK 已初始化（插件会自动完成）。

## 扩展新的登录方式

1. 新建 `lib/src/providers/xxx_auth.dart`，实现 `AuthMethod`（`signIn` / `signOut` / `getCurrentUser` / `buildButton`）。
2. 新建 `lib/src/config/xxx_auth_config.dart`，实现 `AuthMethodConfig`。
3. 在 `WxxAuthConfig.methods` 中加入 `XxxAuthConfig(...)` 即可，UI 会自动渲染。

## API 概览

- `WxxAuth.init(WxxAuthConfig)` —— 统一初始化，返回并注册 `WxxAuthController`。
- `WxxAuth.controller` —— 全局登录控制器（未 init 前访问会抛异常）。
- `WxxAuthView` —— 登录视图组件（可作页面主体 / 弹窗内容）。
- `WxxAuthConfig` / `GoogleAuthConfig` / `AppleAuthConfig` / `TaptapAuthConfig` / `WxxAuthUiConfig` —— 配置。
- `AuthUser` —— 登录结果模型。
- `TaptapComplianceStatus` / `TaptapComplianceResult` —— TapTap 防沉迷合规状态与结果。
- `WxxAuthController.compliance` —— TapTap 防沉迷校验结果（可观察）。
