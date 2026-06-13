-- ═══════════════════════════════════════════════════════════════════════
-- TUNNL — Migration v4
--   • Coupon engine (coupons + coupon_redemptions)
--   • 5000 MCQ exam-wise grouping (mcq_exams)
--   • transactions.coupon_code column
--
-- Idempotent. MySQL 5.7+ compatible (uses a stored proc to add columns
-- only when missing). Run AFTER v2_align_schema.sql.
-- ═══════════════════════════════════════════════════════════════════════

DELIMITER $$

DROP PROCEDURE IF EXISTS tunnl_add_col_v4$$
CREATE PROCEDURE tunnl_add_col_v4(
    IN p_table  VARCHAR(64),
    IN p_col    VARCHAR(64),
    IN p_def    VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = p_table
          AND COLUMN_NAME  = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_col, '` ', p_def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════
-- COUPONS
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `coupons` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `code`           VARCHAR(50)  NOT NULL,
    `description`    VARCHAR(255) DEFAULT '',
    -- 'percent' → discount_value is a % (0-100)
    -- 'flat'    → discount_value is rupees off
    `discount_type`  ENUM('percent','flat') NOT NULL DEFAULT 'percent',
    `discount_value` DECIMAL(10,2) NOT NULL DEFAULT 0,
    -- Optional guards
    `min_amount`     INT DEFAULT 0,        -- minimum order rupees to qualify
    `max_discount`   INT DEFAULT 0,        -- cap on percent discounts (0 = no cap)
    `usage_limit`    INT DEFAULT 0,        -- 0 = unlimited total uses
    `used_count`     INT DEFAULT 0,
    `per_user_limit` INT DEFAULT 1,        -- 0 = unlimited per user
    `expires_at`     DATE DEFAULT NULL,    -- NULL = never expires
    `is_active`      TINYINT DEFAULT 1,
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_code` (`code`),
    KEY `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `coupon_redemptions` (
    `id`           INT AUTO_INCREMENT PRIMARY KEY,
    `coupon_id`    INT NOT NULL,
    `code`         VARCHAR(50) NOT NULL,
    `user_id`      INT NOT NULL,
    `order_id`     VARCHAR(200) DEFAULT '',
    `discount`     INT DEFAULT 0,
    `final_amount` INT DEFAULT 0,
    `status`       ENUM('pending','success') DEFAULT 'pending',
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_coupon` (`coupon_id`),
    KEY `idx_user`   (`user_id`),
    KEY `idx_order`  (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- transactions: remember which coupon was applied
CALL tunnl_add_col_v4('transactions', 'coupon_code', 'VARCHAR(50) DEFAULT ""');
CALL tunnl_add_col_v4('transactions', 'discount',    'INT DEFAULT 0');

-- Sample coupon (50% off) — safe to keep or delete from the admin UI
INSERT IGNORE INTO `coupons`
  (`code`, `description`, `discount_type`, `discount_value`, `usage_limit`, `is_active`)
VALUES
  ('WELCOME50', 'Launch offer — 50% off', 'percent', 50, 0, 1);

-- ═══════════════════════════════════════════════════════════════════════
-- MCQ EXAMS — lets admin group the "5000 Speed MCQs" exam-wise
-- (SSC, Railway, …) just like Previous Year. Sets are linked by exam_name.
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `mcq_exams` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `exam_name`      VARCHAR(100) NOT NULL,
    `exam_full_name` VARCHAR(200) DEFAULT '',
    `exam_category`  ENUM('SSC','RAILWAY','BANK','DEFENCE','OTHER') DEFAULT 'OTHER',
    `icon`           VARCHAR(50)  DEFAULT 'school',
    `difficulty`     ENUM('Easy','Medium','Hard') DEFAULT 'Medium',
    `is_premium`     TINYINT DEFAULT 0,
    `is_active`      TINYINT DEFAULT 1,
    `sort_order`     INT DEFAULT 1,
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_mcq_exam_name` (`exam_name`),
    KEY `idx_mcq_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed a few common exams (safe / idempotent)
INSERT IGNORE INTO `mcq_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `difficulty`, `is_premium`, `is_active`, `sort_order`)
VALUES
  ('SSC',     'Staff Selection Commission',  'SSC',     'school',          'Medium', 0, 1, 1),
  ('Railway', 'Railway Recruitment Board',   'RAILWAY', 'train',           'Medium', 0, 1, 2),
  ('Banking', 'Banking (IBPS / SBI)',        'BANK',    'account_balance', 'Medium', 0, 1, 3);

DROP PROCEDURE IF EXISTS tunnl_add_col_v4;
