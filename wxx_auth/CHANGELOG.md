## 0.0.2

* 新增 TapTap 登录（基于 `flutter_taptap`，path 依赖），复用同一套 `AuthMethod` 扩展架构。
* 新增**可选**的 TapTap 防沉迷（实名 / 未成年人保护）校验：登录后按 `enableAntiAddiction` 开关自动跑 `startCompliance`，结果通过 `onComplianceResult` 回调与 `WxxAuthController.compliance` 暴露。
* `AuthMethod` 新增 `initialize()` 平台 SDK 预热钩子，`WxxAuth.init` 统一调用。
* 新增 `TaptapAuthConfig` 与快捷构造 `WxxAuthConfig.googleAppleTapTap(...)`。
* 新增 `TaptapComplianceStatus` / `TaptapComplianceResult` 防沉迷状态模型。

## 0.0.1

* 初始版本：第三方登录整合插件骨架。
* 接入 Google 登录（google_sign_in ^7.2.0）与 Apple 登录（sign_in_with_apple ^8.2.0）。
* 可扩展的 `AuthMethod` 抽象 + 可选/统一配置 `WxxAuthConfig`，基于 GetX（`get ^4.7.2`）的状态管理。
* 提供 `WxxAuthView` 登录界面与 `WxxAuthController` 全局控制器。
