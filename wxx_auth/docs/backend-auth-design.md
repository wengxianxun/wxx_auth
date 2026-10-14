# wxx_auth 后台用户表设计

本文档配套 `database/user_auth_schema.sql`（MySQL 8.0 DDL）。设计目标：**一套表结构同时支撑 Google / Apple / TapTap 三种登录，并支持「同一用户绑定多个平台账号」。**

---

## 1. 核心思路

插件本身是无后台的 Flutter 端登录整合层，它只负责拿到第三方平台的用户凭据（`AuthUser`）。是否把登录信息落库、如何落库，由你的后台决定。

**为什么不把所有字段塞进一张表？**
- 用户可能先用 Google 注册，后来又用 Apple / TapTap 登录——我们希望这还是「同一个人」。
- 每个平台返回的字段不同（Apple 不保证返回邮箱、TapTap 没有 email 但有 unionId），一张扁平表会出现大量互斥的空列。

因此采用 **两表分离**：

| 表 | 作用 | 与插件对应关系 |
|---|---|---|
| `users` | 平台统一用户（一人一行） | 聚合后的用户档案 |
| `user_oauth_identities` | 每种第三方登录一行 | 直接对应一次 `AuthUser` 登录 |

> 防沉迷状态、登录会话等本设计不落库；如需按需自行扩展。

---

## 2. 字段映射（插件 `AuthUser` → 数据库）

| `AuthUser` 字段 | 落库位置 | 说明 |
|---|---|---|
| `providerId` (`google/apple/taptap`) | `user_oauth_identities.provider` | 登录入口的查找键之一 |
| `id`（第三方唯一ID） | `user_oauth_identities.provider_user_id` | Google=sub / Apple=userIdentifier / TapTap=openId |
| `email` | `users.email`（主）+ `identity.email`（来源） | TapTap 无邮箱，可为空；Apple 仅首次授权返回 |
| `displayName` | `users.display_name` + `identity.display_name` | |
| `photoUrl` | `users.avatar_url` + `identity.avatar_url` | |
| `idToken`（Google） | `identity.id_token` | 短期凭证，验证签名后即丢弃 |
| `identityToken`（Apple） | `identity.id_token` | 同上 |
| `authorizationCode`（Apple） | 后端换 session 用，验证后丢弃 | 可临时存 `raw_data` 便于排查 |
| `accessToken`（Google / TapTap） | `identity.access_token`（加密） | 仅当后端需调第三方 API 才存 |
| `raw`（TapTap 含 unionId / macKey / secret） | `identity.raw_data`（剔除敏感字段） | **macKey / secret 绝不能明文入库** |
| TapTap `unionId` | `identity.union_id` | 同开发者跨应用打通用户 |

`users` 表里的 `email / display_name / avatar_url` 是「最新一次登录来源的展示信息」，由 `user_oauth_identities` 同步而来，方便业务直接读主表，不必每次 join。

---

## 3. 后端登录 / 验证流程（建议）

客户端拿到第三方凭证后，**必须发到你的后台做真实性校验**，绝不能信任客户端直接声称「我已登录」。流程：

1. 客户端调用 `WxxAuth.signInWith('google' | 'apple' | 'taptap')`，得到 `AuthUser`。
2. 客户端把关键凭证发给后台，例如：
   - Google：`idToken`
   - Apple：`identityToken` + `authorizationCode`
   - TapTap：`accessToken` + `openId`（或 `macKey/secret` 由后台换用户态）
3. **后台校验**：
   - Google：用 Google 公钥验证 `id_token` JWT 签名与 `aud`/`iss`；或从 `serverClientId` 换用户信息。
   - Apple：用 Apple 公钥验证 `identityToken`，并用 `authorizationCode` 调 Apple 的 token 端点换取 session。
   - TapTap：用 `clientToken` + `macKey/secret` 校验登录态（参考 `flutter_taptap` 的登录校验）。
4. 校验通过后，在 `user_oauth_identities` 上 `UPSERT`：
   - 按 `(provider, provider_user_id)` 查找是否已存在。
   - 存在 → 更新 `email/display_name/avatar_url/token` 等（注意：**新 email 为 null 时不要覆盖旧值**）。
   - 不存在 → 新建 `users` 行（生成 `uuid`），再插入 identity 关联。
5. 返回后台自己的 **JWT（access token）** 给客户端用于后续鉴权。

> 第 3 步的第三方校验是关键安全闸门，跳过它等于任何人都能伪造任意用户登录你的系统。

---

## 4. 安全要点（务必遵守）

1. **第三方 token（idToken / identityToken / authorizationCode）是短期凭证**：后台校验完就丢，不要长期明文落库。`id_token` / `access_token` 列如确需保留，请加密（AES-256）并在应用层加解密。
2. **TapTap 的 `macKey` / `secret` 属于高敏感凭证**：绝对不要明文写进 `raw_data`，入库前从 `raw` 中剔除，或仅存哈希。
3. **永远后台校验**：见第 3 节，不要信任客户端传来的身份。
4. 全链路 **HTTPS**；`users.uuid` 作为对外 ID，不要暴露 `users.id` 自增主键。

---

## 5. 迁移到 PostgreSQL（如用 PG）

SQL 文件是 MySQL 8.0 语法，迁移到 PG 的关键差异：
- `BIGINT UNSIGNED AUTO_INCREMENT` → `BIGINT GENERATED ALWAYS AS IDENTITY` 或 `BIGSERIAL`。
- `JSON` 类型 PG 原生支持，可保留。
- `ON UPDATE CURRENT_TIMESTAMP` 无原生支持，用触发器或在应用层维护 `updated_at`。
- `CHAR(36)` uuid 可改为 PG 的 `uuid` 类型并配合 `gen_random_uuid()`。
- `TINYINT` → `SMALLINT` 或 `BOOLEAN`（布尔语义列）。
- 字符串类型 `VARCHAR` / `TEXT` 一致。
