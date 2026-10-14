-- ============================================================
-- wxx_auth 后台用户表设计（MySQL 8.0）
-- 满足 wxx_auth 登录插件：Google / Apple / TapTap
-- 设计原则：统一用户与登录方式解耦，支持同一用户绑定多平台
-- 仅两张表：users（统一用户）+ user_oauth_identities（第三方身份）
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1) 平台统一用户主表：每个真实用户一行，与登录方式无关
-- ------------------------------------------------------------
CREATE TABLE `users` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid`          CHAR(36) NOT NULL                COMMENT '对外用户标识，避免在接口暴露自增主键',
  `email`         VARCHAR(255) NULL                COMMENT '主邮箱，可为空（TapTap 不返回邮箱）',
  `display_name`  VARCHAR(128) NULL,
  `avatar_url`    VARCHAR(512) NULL,
  `status`        TINYINT NOT NULL DEFAULT 1       COMMENT '1=正常 2=封禁',
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='平台统一用户';

-- ------------------------------------------------------------
-- 2) 第三方登录身份表：每种登录方式一行，支持同一用户绑定多平台
--    (provider, provider_user_id) 唯一 -> 登录入口的查找键
-- ------------------------------------------------------------
CREATE TABLE `user_oauth_identities` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`           BIGINT UNSIGNED NOT NULL,
  `provider`          VARCHAR(32) NOT NULL            COMMENT 'google | apple | taptap',
  `provider_user_id`  VARCHAR(255) NOT NULL           COMMENT '第三方唯一ID：Google sub / Apple userIdentifier / TapTap openId',
  `union_id`          VARCHAR(255) NULL               COMMENT 'TapTap unionId，同开发者跨应用打通',
  `email`             VARCHAR(255) NULL               COMMENT '该平台返回的邮箱（Apple 仅首次授权返回，后续可能为 null）',
  `display_name`      VARCHAR(128) NULL,
  `avatar_url`        VARCHAR(512) NULL,
  `id_token`          TEXT NULL                      COMMENT 'Google idToken / Apple identityToken；短期凭证，后端验证签名后即丢弃，勿长期明文存储',
  `access_token`      TEXT NULL                      COMMENT '第三方 access_token；仅当后端需调用第三方 API 才存，必须加密(AES)存储',
  `refresh_token`     TEXT NULL                      COMMENT '如有，需加密存储',
  `token_expires_at`  DATETIME NULL,
  `raw_data`          JSON NULL                      COMMENT '第三方原始返回（务必剔除 macKey/secret 等敏感字段后再存）',
  `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_provider_uid` (`provider`, `provider_user_id`),
  KEY `idx_union_id` (`union_id`),
  KEY `idx_user` (`user_id`),
  CONSTRAINT `fk_identity_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='第三方登录身份';
