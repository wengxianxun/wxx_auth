## 0.0.1

* 初始版本：第三方登录整合插件骨架。
* 接入 Google 登录（google_sign_in ^7.2.0）与 Apple 登录（sign_in_with_apple ^8.2.0）。
* 可扩展的 `AuthMethod` 抽象 + 可选/统一配置 `WxxAuthConfig`，基于 GetX（`get ^4.7.2`）的状态管理。
* 提供 `WxxAuthView` 登录界面与 `WxxAuthController` 全局控制器。
